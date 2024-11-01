# Clear existing data to avoid duplication
Stock.destroy_all
HistoricalPrice.destroy_all

# Create sample stocks
apple = Stock.create(symbol: "AAPL", company_name: "Apple Inc.", sector: "Technology", industry: "Consumer Electronics")
tesla = Stock.create(symbol: "TSLA", company_name: "Tesla Inc.", sector: "Automotive", industry: "Electric Vehicles")

# Helper to generate random historical prices
def generate_historical_prices(stock, start_date, days)
  days.times do |i|
    HistoricalPrice.create!(
      stock: stock,
      date: start_date - i.days,
      price: rand(100..300)  # Random price between $100 and $300
    )
  end
end

# Generate historical prices for the past 30 days for each stock
generate_historical_prices(apple, Date.today, 30)
generate_historical_prices(tesla, Date.today, 30)

puts "Seed data created successfully with stocks and historical prices."
