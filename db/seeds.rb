# Clear existing data to avoid duplication
HistoricalPrice.destroy_all
Stock.destroy_all

# Now proceed with seeding Stocks and HistoricalPrices
apple = Stock.create!(symbol: "AAPL", company_name: "Apple Inc.", sector: "Technology", industry: "Consumer Electronics")
tesla = Stock.create!(symbol: "TSLA", company_name: "Tesla Inc.", sector: "Automotive", industry: "Electric Vehicles")

# Helper to generate random historical prices for each stock
def generate_historical_prices(stock, start_date, days)
  days.times do |i|
    open_price = rand(100.0..300.0).round(2)          # Random open price
    close_price = rand(100.0..300.0).round(2)         # Random close price
    high_price = [open_price, close_price].max + rand(0.0..10.0).round(2) # High >= open/close
    low_price = [open_price, close_price].min - rand(0.0..10.0).round(2)  # Low <= open/close
    volume = rand(1_000_000..10_000_000)              # Random volume between 1M and 10M

    HistoricalPrice.create!(
      stock_id: stock.id,
      date: start_date - i.days,
      open: open_price,
      high: high_price,
      low: low_price,
      close: close_price,
      volume: volume
    )
  end
end

# Generate historical prices for the past 30 days for each stock
generate_historical_prices(apple, Date.today, 30)
generate_historical_prices(tesla, Date.today, 30)

puts "Seed data created successfully with stocks and historical prices."
