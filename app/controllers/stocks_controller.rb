class StocksController < ApplicationController

  def index
    @stocks = Stock.includes(:predictions).all

    # Show the button if any stock lacks today's predictions
    today_predictions_count = Prediction.where(date: Date.today).distinct.count(:stock_id)
    @show_run_predictions_button = today_predictions_count < @stocks.count
    @top_stocks = TopStock.includes(stock: :predictions).map(&:stock)
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

    # Save new top stocks
    top_stocks.each do |stock|
      TopStock.create(stock: stock)
    end

    redirect_to stocks_path, notice: 'Top stocks have been refreshed.'
  end
end
