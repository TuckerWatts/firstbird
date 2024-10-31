namespace :stocks do
  desc "Fetch historical stock data"
  task fetch_data: :environment do
    Stock.find_each do |stock|
      FetchStockDataJob.perform_later(stock.id)
    end
  end
end
