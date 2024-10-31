class FetchStockDataJob < ApplicationJob
  queue_as :default

  def perform(stock_id)
    stock = Stock.find(stock_id)
    fetcher = StockDataFetcher.new(stock.symbol)
    historical_prices = fetcher.fetch_daily_adjusted

    return unless historical_prices

    historical_prices.each do |price_data|
      stock.historical_prices.find_or_create_by(date: price_data[:date]) do |hp|
        hp.open = price_data[:open]
        hp.high = price_data[:high]
        hp.low = price_data[:low]
        hp.close = price_data[:close]
        hp.volume = price_data[:volume]
      end
    end
  end
end
