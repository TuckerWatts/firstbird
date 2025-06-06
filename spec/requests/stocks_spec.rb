# spec/requests/stocks_spec.rb

require 'rails_helper'

RSpec.describe "Stocks", type: :request do
  let(:user) { create(:user) }
  let(:stock) { create(:stock, symbol: "STOCK23") }

  before do
    sign_in user
    
    # Stub the API calls
    allow_any_instance_of(Stock).to receive(:latest_price).and_return(150.0)
    allow_any_instance_of(Stock).to receive(:fetch_and_update_current_price).and_return(150.0)
    allow_any_instance_of(StockDataFetcher).to receive(:fetch_recent_data).and_return({
      'c' => 150.0, 'h' => 155.0, 'l' => 145.0, 'o' => 148.0, 't' => Time.current.to_i, 'v' => 1000000
    })
  end

  describe "GET /stocks" do
    it "returns a successful response" do
      get stocks_path
      expect(response).to be_successful
    end
  end

  describe "GET /stocks/new" do
    it "returns a successful response" do
      get new_stock_path
      expect(response).to be_successful
    end
  end

  describe "GET /stocks/:id" do
    it "returns a successful response" do
      get stock_path(stock)
      expect(response).to be_successful
    end
  end

  describe "GET /stocks/:id/edit" do
    it "returns a successful response" do
      get edit_stock_path(stock)
      expect(response).to be_successful
    end
  end

  describe "POST /stocks" do
    let(:valid_attributes) {
      {
        symbol: "AAPL",
        company_name: "Apple Inc.",
        sector: "Technology",
        industry: "Consumer Electronics"
      }
    }

    it "creates a new stock and redirects" do
      expect {
        post stocks_path, params: { stock: valid_attributes }
      }.to change(Stock, :count).by(1)
      expect(response).to redirect_to(stock_path(Stock.last))
    end
  end

  describe "PATCH /stocks/:id" do
    let(:new_attributes) {
      {
        company_name: "Updated Company Name"
      }
    }

    it "updates the stock and redirects" do
      patch stock_path(stock), params: { stock: new_attributes }
      stock.reload
      expect(stock.company_name).to eq("Updated Company Name")
      expect(response).to redirect_to(stock_path(stock))
    end
  end

  describe "DELETE /stocks/:id" do
    it "destroys the stock and redirects" do
      stock # create the stock
      expect {
        delete stock_path(stock)
      }.to change(Stock, :count).by(-1)
      expect(response).to redirect_to(stocks_path)
    end
  end
end
