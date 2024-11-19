class FetchStockDataJob < ApplicationJob
  queue_as :default

  def perform(stock_id = nil)
    stocks = stock_id ? [Stock.find(stock_id)] : Stock.all

    stocks.each do |stock|
      fetcher = StockDataFetcher.new(stock.symbol)

      # Fetch and update the latest price
      data = fetcher.fetch_recent_data
      if data
        stock.update(latest_price: data[:current_price])
      else
        Rails.logger.error "Failed to fetch recent data for #{stock.symbol}"
      end

      # Fetch and store historical data
      historical_data = fetcher.fetch_historical_prices(100) # Adjust '100' as needed
      historical_data.each do |entry|
        stock.historical_prices.find_or_create_by(date: entry[:date]) do |hp|
          hp.open = entry[:open]
          hp.high = entry[:high]
          hp.low = entry[:low]
          hp.close = entry[:close]
          hp.volume = entry[:volume]
        end
      end

      # Calculate moving averages and store predictions
      calculate_and_store_predictions(stock)
    end
  end

  private

  def calculate_and_store_predictions(stock)
    prediction = stock.predictions.find_or_initialize_by(date: Date.today)
    prediction.prediction_method = 'Moving Averages'

    # Calculate moving averages
    prediction.ma_5 = stock.moving_average(5)
    prediction.ma_10 = stock.moving_average(10)
    prediction.ma_20 = stock.moving_average(20)
    prediction.actual_price = stock.latest_price
    prediction.save
  end
end
