require 'rails_helper'

RSpec.describe FetchStockDataJob, type: :job do
  let(:stock) { create(:stock) }
  let(:api_response) do
    {
      'c' => 150.0,
      'h' => 155.0,
      'l' => 145.0,
      'o' => 148.0,
      't' => Time.current.to_i,
      'v' => 1000000
    }
  end

  before do
    stub_request(:get, /api.finnhub.io/).to_return(
      status: 200,
      body: api_response.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  it "fetches stock data and populates historical prices" do
    expect {
      FetchStockDataJob.perform_now(stock.id)
    }.to change(StockPrice, :count).by(1)
  end

  it "updates stock prices for each stock" do
    FetchStockDataJob.perform_now(stock.id)
    latest_price = stock.stock_prices.last
    expect(latest_price.close).to eq(150.0)
  end

  context "when API request fails" do
    before do
      stub_request(:get, /api.finnhub.io/).to_return(
        status: 500,
        body: "Internal Server Error",
        headers: { 'Content-Type' => 'text/plain' }
      )
    end

    it "handles the error gracefully" do
      expect {
        FetchStockDataJob.perform_now(stock.id)
      }.not_to raise_error
    end
  end
end
