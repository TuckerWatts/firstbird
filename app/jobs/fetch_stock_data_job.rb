class FetchStockDataJob < ApplicationJob
  queue_as :default

  def perform(stock_id = nil)
    stocks = stock_id ? [Stock.find(stock_id)] : Stock.all

    stocks.each do |stock|
      fetcher = StockDataFetcher.new(stock.symbol)
      data = fetcher.fetch_recent_data

      if data.is_a?(Hash)
        current_price = data[:current_price]
        # Update the stock's latest_price attribute
        stock.update(latest_price: current_price)
      else
        Rails.logger.error "Failed to fetch data for #{stock.symbol}"
      end
    end
  end
end
