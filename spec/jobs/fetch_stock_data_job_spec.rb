require 'rails_helper'

RSpec.describe FetchStockDataJob, type: :job do
  before do
    # Mock the API response
    stub_request(:get, /www.alphavantage.co/).to_return(
      status: 200,
      body: {
        "Time Series (Daily)" => {
          "2023-10-10" => {
            "1. open" => "142.00",
            "2. high" => "144.00",
            "3. low" => "141.00",
            "4. close" => "143.00",
            "6. volume" => "1000000"
          }
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end
  
  it "fetches stock data and populates historical prices" do
    stock = Stock.create(symbol: "AAPL", company_name: "Apple Inc.")
    expect {
      FetchStockDataJob.perform_now(stock.id)
    }.to change { stock.historical_prices.count }.by_at_least(1)
  end
end
