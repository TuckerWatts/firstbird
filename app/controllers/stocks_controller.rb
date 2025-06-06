class StocksController < ApplicationController
  before_action :set_stock, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show]

  def index
    # Only load minimal data for initial page load
    @stocks = Stock.order(created_at: :desc).limit(20)
    
    # We'll load these components asynchronously
    @top_stocks = []
    @desired_stocks = []
    
    respond_to do |format|
      format.html
      format.json { render json: @stocks }
    end
  end

  # New action to load historical data separately
  def historical_data
    # Cache historical success data
    @historical_success = Rails.cache.fetch("historical_success", expires_in: 2.hours) do
      days = 30.days.ago.to_date..Date.today
      
      # Eager load all predictions for the last 30 days in a single query
      # Use left join instead of includes to avoid the warning
      date_predictions = Prediction.joins("LEFT JOIN stocks ON stocks.id = predictions.stock_id")
                                  .where(date: days)
                                  .select("predictions.*, stocks.id as stock_id, stocks.symbol")
                                  .group_by(&:date)
      
      days.map do |day|
        predictions = date_predictions[day] || []
        successful = count_successful_predictions(predictions)
        total = predictions.size
        
        {
          date: day,
          successful: successful,
          total: total,
          rate: total > 0 ? (successful.to_f / total) * 100 : 0,
          benchmark_rate: calculate_benchmark_rate(predictions),
          error_distribution: calculate_error_distribution(predictions)
        }
      end
    end
    
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("historical_data", partial: "historical_data") }
      format.html { render partial: 'historical_data' }
    end
  end

  # New action to load top stocks separately
  def top_stocks
    @top_stocks = Rails.cache.fetch("top_stocks", expires_in: 30.minutes) do
      if defined?(TopStock)
        TopStock.includes(:stock)
                .order(created_at: :desc)
                .limit(10)
                .map(&:stock)
                .compact
      else
        []
      end
    end
                    
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("top_stocks", partial: "top_stocks") }
      format.html { render partial: 'top_stocks' }
    end
  end

  # New action to load desired stocks separately
  def desired_stocks
    @desired_stocks = Rails.cache.fetch("desired_stocks", expires_in: 30.minutes) do
      begin
        if defined?(DesiredStock)
          DesiredStock.includes(:stock)
                      .order(created_at: :desc)
                      .limit(10)
                      .map(&:stock)
                      .compact
        else
          []
        end
      rescue
        []
      end
    end
                    
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("desired_stocks", partial: "desired_stocks") }
      format.html { render partial: 'desired_stocks' }
    end
  end

  # New action to load predictions (paginated) separately
  def stock_predictions
    page = params[:page] || 1
    
    @stocks = Rails.cache.fetch("stock_predictions/page/#{page}", expires_in: 15.minutes) do
      Stock.order(created_at: :desc)
           .includes(:predictions) # Eager load predictions
           .page(page)
           .per(10)
           .to_a
    end
    
    # Preload latest_prediction and cache individually for each stock
    @stocks.each do |stock|
      stock.latest_prediction # This triggers the cached method in the model
    end
                  
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("stock_predictions", partial: "stock_predictions") }
      format.html { render partial: 'stock_predictions' }
    end
  end

  def show
    # Use a shared cache key for all stock-related data
    cache_key = "stock/#{@stock.id}/#{@stock.updated_at}"
    
    @analysis = Rails.cache.fetch("#{cache_key}/analysis", expires_in: 1.hour) do
      StockAnalysisService.new(@stock).analyze
    end
    
    # Fetch all required data in a single cache hit
    cached_data = Rails.cache.fetch("#{cache_key}/data", expires_in: 30.minutes) do
      historical_prices = @stock.historical_prices.order(date: :desc).limit(20).to_a
      latest_prediction = @stock.predictions.order(prediction_date: :desc).limit(1).first
      
      # Calculate moving averages from historical prices
      recent_prices = historical_prices.reverse
      moving_averages = {}
      
      if recent_prices.present?
        moving_averages[:ma5] = recent_prices.last([5, recent_prices.size].min).map(&:close).mean
        moving_averages[:ma10] = recent_prices.last([10, recent_prices.size].min).map(&:close).mean
        moving_averages[:ma20] = recent_prices.map(&:close).mean if recent_prices.size > 0
      end
      
      {
        historical_prices: historical_prices,
        latest_prediction: latest_prediction,
        moving_averages: moving_averages
      }
    end
    
    # Assign cached data to instance variables
    @historical_prices = cached_data[:historical_prices]
    @latest_prediction = cached_data[:latest_prediction]
    @moving_average_5 = cached_data[:moving_averages][:ma5]
    @moving_average_10 = cached_data[:moving_averages][:ma10]
    @moving_average_20 = cached_data[:moving_averages][:ma20]

    respond_to do |format|
      format.html
      format.json { render json: @stock }
    end
  end

  def new
    @stock = Stock.new
  end

  def edit
  end

  def create
    @stock = Stock.new(stock_params)
    authorize @stock

    if @stock.save
      StockDataFetcher.new(@stock.symbol).fetch_recent_data
      StockAnalysisService.new(@stock).update_historical_data

      respond_to do |format|
        format.html { redirect_to @stock, notice: 'Stock was successfully created.' }
        format.json { render json: @stock, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @stock.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @stock.update(stock_params)
      StockDataFetcher.new(@stock.symbol).fetch_recent_data
      StockAnalysisService.new(@stock).update_historical_data

      respond_to do |format|
        format.html { redirect_to @stock, notice: 'Stock was successfully updated.' }
        format.json { render json: @stock }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @stock.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @stock.destroy
    respond_to do |format|
      format.html { redirect_to stocks_url, notice: 'Stock was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  def refresh_data
    @stock = Stock.find(params[:id])
    authorize @stock

    StockDataFetcher.new(@stock.symbol).fetch_recent_data
    StockAnalysisService.new(@stock).update_historical_data

    respond_to do |format|
      format.html { redirect_to @stock, notice: 'Stock data was successfully refreshed.' }
      format.json { render json: @stock }
    end
  end

  def refresh_top_stocks
    fetcher = TopStocksFetcher.new
    top_stocks = fetcher.fetch_top_meme_stocks

    if top_stocks.any?
      # Clear existing top stocks
      TopStock.delete_all

      top_stocks.each do |stock|
        TopStock.create!(stock: stock)
      end

      redirect_to stocks_path, notice: 'Top stocks have been refreshed.'
    else
      redirect_to stocks_path, alert: 'No top stocks found with favorable call option recommendations.'
    end
  end

  # Action to show day details (best performers, etc.)
  def day_details
    @day = Date.parse(params[:date])
    @best_performers = best_performers_for_day(@day)
    @successful_stocks = successful_stocks_for_day(@day)
    respond_to do |format|
      format.turbo_stream
      format.html { render :day_details } # fallback if needed
    end
  end

  private

  def set_stock
    @stock = Stock.find(params[:id])
  end

  def authorize_stock
    authorize @stock
  end

  def stock_params
    params.require(:stock).permit(:symbol, :company_name, :sector, :industry)
  end

  def count_successful_predictions(predictions)
    predictions.count { |prediction| prediction_successful?(prediction) }
  end

  def prediction_successful?(prediction)
    return false unless prediction.actual_price.present? && prediction.predicted_price.present?
    
    error = ((prediction.actual_price - prediction.predicted_price) / prediction.actual_price).abs
    error <= 0.01 # 1% threshold
  end

  def calculate_benchmark_rate(predictions)
    return 0 if predictions.empty?
    
    # Count predictions where the benchmark was successful
    benchmark_successes = predictions.count do |prediction|
      next false unless prediction.actual_price.present? && prediction.benchmark_price.present?
      
      benchmark_error = ((prediction.actual_price - prediction.benchmark_price) / prediction.actual_price).abs
      benchmark_error <= 0.01 # 1% threshold
    end
    
    (benchmark_successes.to_f / predictions.size) * 100
  end

  def calculate_error_distribution(predictions)
    distribution = { low: 0, medium: 0, high: 0 }
    return distribution if predictions.empty?
    
    predictions.each do |prediction|
      next unless prediction.actual_price.present? && prediction.predicted_price.present?
      
      error = ((prediction.actual_price - prediction.predicted_price) / prediction.actual_price).abs
      
      if error <= 0.01
        distribution[:low] += 1
      elsif error <= 0.05
        distribution[:medium] += 1
      else
        distribution[:high] += 1
      end
    end
    
    distribution
  end

  # Find best performing stocks for a given day (those with the closest predictions and successful criteria).
  def best_performers_for_day(day)
    # Get all predictions for this day in a single query
    predictions = Prediction.includes(:stock).where(prediction_date: day).to_a
    
    # Filter successful predictions
    successful_predictions = predictions.select { |p| prediction_successful?(p) }
    
    # Sort by how close they were to predicted price and get the top 5
    successful_predictions.sort_by do |prediction|
      ((prediction.actual_price - prediction.predicted_price).abs / prediction.predicted_price) if prediction.predicted_price
    end.first(5).map(&:stock)
  end

  def successful_stocks_for_day(day)
    # Get all predictions for this day in a single query
    predictions = Prediction.includes(:stock).where(prediction_date: day).to_a
    
    # Return stocks with successful predictions
    predictions.select { |p| prediction_successful?(p) }.map(&:stock)
  end
end
