require 'rails_helper'

RSpec.describe "Admins", type: :request do
  let(:user) { create(:user, admin: true) }
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
    sign_in user
    stub_request(:get, /api.finnhub.io/).to_return(
      status: 200,
      body: api_response.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  describe "GET /fetch_data" do
    it "redirects to stocks path" do
      get "/admin/fetch_data"
      expect(response).to redirect_to(stocks_path)
    end

    it "enqueues the FetchStockDataJob" do
      create(:stock) # Create a stock to fetch data for
      expect {
        get "/admin/fetch_data"
      }.to have_enqueued_job(FetchStockDataJob)
    end
  end
end
