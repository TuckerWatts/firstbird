class FetchStockDataJob < ApplicationJob
  queue_as :default

  def perform(stock_id)
    stock = Stock.find(stock_id)
    fetcher = StockDataFetcher.new(stock.symbol)
    data = fetcher.fetch_recent_data

    return unless data

    StockPrice.create!(
      stock: stock,
      date: Time.zone.at(data['t']).to_date,
      open: data['o'],
      high: data['h'],
      low: data['l'],
      close: data['c'],
      volume: data['v']
    )

    stock.update!(latest_price: data['c'])

    # Calculate predictions if we have at least some data
    calculate_and_store_predictions(stock)
  end

  private

  def calculate_and_store_predictions(stock)
    future_dates = [
      Date.today + 7.days,
      Date.today + 1.month,
      Date.today + 3.months
    ]

    future_dates.each do |target_date|
      prediction = stock.predictions.find_or_initialize_by(prediction_date: target_date, date: Date.today)
      prediction.prediction_method = 'Moving Averages'
      predicted_price = stock.calculate_future_prediction(target_date)
      prediction.predicted_price = predicted_price || 0.0
      prediction.actual_price = nil
      prediction.save!
    end
  end
end
