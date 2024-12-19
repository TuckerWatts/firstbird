class StocksController < ApplicationController

  def index
    timeframe = Time.zone.today + 1.month

    # Preload all necessary data so no fetching is triggered during sorting
    all_stocks = Stock.includes(:historical_prices, :predictions).to_a

    # Ensure all stocks have latest_price updated and historical_prices present if needed
    # But do this outside of sorting and prediction calculations
    all_stocks.each do |stock|
      # Only update if not present - avoid multiple calls
      if stock.latest_price.nil?
        stock.fetch_and_update_current_price rescue nil
      end
      if stock.historical_prices.empty?
        stock.fetch_and_update_historical_prices rescue nil
      end
    end

    # Precompute predictions once per stock to avoid repeated calls to calculate_future_prediction
    predictions_map = {}
    all_stocks.each do |stock|
      predictions_map[stock.id] = stock.calculate_future_prediction(timeframe)
    end

    # Sort stocks by profitability using the precomputed predictions, select top 10
    @stocks = all_stocks.sort_by do |stock|
      predicted_price = predictions_map[stock.id]
      if predicted_price && stock.latest_price
        ((predicted_price - stock.latest_price) / stock.latest_price) * 100.0
      else
        -Float::INFINITY
      end
    end.reverse.first(10)

    # Get today's prediction from the last stock in the sorted list (if available)
    @today_prediction = @stocks.last&.predictions&.find_by(date: Date.today)
    @show_run_predictions_button = @today_prediction.nil?

    # Handle TopStocks similarly, but don't re-fetch data again
    top_stocks_all = TopStock.includes(stock: [:historical_prices, :predictions]).map(&:stock)

    # Update data for top stocks if necessary
    top_stocks_all.each do |stock|
      if stock.latest_price.nil?
        stock.fetch_and_update_current_price rescue nil
      end
      if stock.historical_prices.empty?
        stock.fetch_and_update_historical_prices rescue nil
      end
    end

    # Precompute predictions for top stocks
    top_predictions_map = {}
    top_stocks_all.each do |stock|
      top_predictions_map[stock.id] = stock.calculate_future_prediction(timeframe)
    end

    @top_stocks = top_stocks_all.sort_by do |stock|
      predicted_price = top_predictions_map[stock.id]
      if predicted_price && stock.latest_price
        ((predicted_price - stock.latest_price) / stock.latest_price) * 100.0
      else
        -Float::INFINITY
      end
    end.reverse.first(10)
  end


  def show
    @stock = Stock.find(params[:id])
    @latest_prediction = @stock.latest_prediction
    @prediction_successful = @stock.last_prediction_successful?
    @moving_average_5 = @stock.moving_average(5)
    @moving_average_10 = @stock.moving_average(10)
    @moving_average_20 = @stock.moving_average(20)
    @historical_prices = @stock.historical_prices.order(date: :desc).limit(5)
    # Get today's prediction
    @today_prediction = @stock.predictions.find_by(date: Date.today)
    # Determine whether to show the run predictions button
    @show_run_predictions_button = @today_prediction.nil?

    @call_option_recommendations = @stock.call_option_recommendations
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
end
