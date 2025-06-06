require 'rails_helper'

RSpec.describe StocksController, type: :controller do
  let(:user) { create(:user) }
  let(:stock) { create(:stock) }

  before do
    sign_in user
  end

  describe "GET #index" do
    before do
      # Create test predictions
      3.times do |i|
        create(:prediction,
          stock: stock,
          date: i.days.ago.to_date,
          prediction_date: i.days.ago.to_date,
          predicted_price: 100.0,
          actual_price: 101.0
        )
      end
    end

    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns @stocks" do
      stock1 = create(:stock)
      stock2 = create(:stock)
      get :index
      expect(assigns(:stocks)).to include(stock1, stock2)
    end

    it "assigns @historical_success" do
      get :index
      expect(assigns(:historical_success)).to be_present
      expect(assigns(:historical_success)).to be_an(Array)
      expect(assigns(:historical_success).first).to include(:date, :successful, :total, :rate)
    end
  end

  describe "GET #historical_data" do
    before do
      # Create test predictions for the last 30 days
      (0..29).each do |days_ago|
        date = days_ago.days.ago.to_date
        create(:prediction,
          stock: stock,
          date: date,
          prediction_date: date,
          predicted_price: 100.0,
          actual_price: 101.0
        )
      end
      
      Rails.cache.clear
    end

    it "returns a successful response" do
      get :historical_data, format: :html
      expect(response).to be_successful
    end

    it "assigns @historical_success" do
      get :historical_data, format: :html
      expect(assigns(:historical_success)).to be_present
      expect(assigns(:historical_success).length).to be <= 30
    end

    it "caches the historical success data" do
      expect(Rails.cache).to receive(:fetch).with("historical_success", expires_in: 2.hours).and_call_original
      get :historical_data, format: :html
    end

    it "calculates success rates correctly" do
      get :historical_data, format: :html
      historical_success = assigns(:historical_success)
      
      day_data = historical_success.first
      expect(day_data).to include(:date, :successful, :total, :rate)
      expect(day_data[:rate]).to be_a(Float)
      expect(day_data[:rate]).to be_between(0.0, 100.0)
    end

    it "handles turbo_stream format" do
      get :historical_data, format: :turbo_stream
      expect(response.media_type).to eq Mime[:turbo_stream]
      expect(response).to render_template('stocks/_historical_data')
    end

    it "handles html format" do
      get :historical_data, format: :html
      expect(response).to render_template(partial: '_historical_data')
    end
  end

  describe "GET #show" do
    it "returns a successful response" do
      get :show, params: { id: stock.id }
      expect(response).to be_successful
    end

    it "assigns @stock" do
      get :show, params: { id: stock.id }
      expect(assigns(:stock)).to eq(stock)
    end

    it "assigns @analysis" do
      get :show, params: { id: stock.id }
      expect(assigns(:analysis)).to be_present
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns a new stock" do
      get :new
      expect(assigns(:stock)).to be_a_new(Stock)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) { { symbol: 'AAPL', company_name: 'Apple Inc.' } }
    let(:invalid_attributes) { { symbol: '', company_name: '' } }

    context "with valid parameters" do
      it "creates a new Stock" do
        expect {
          post :create, params: { stock: valid_attributes }
        }.to change(Stock, :count).by(1)
      end

      it "redirects to the created stock" do
        post :create, params: { stock: valid_attributes }
        expect(response).to redirect_to(Stock.last)
      end
    end

    context "with invalid parameters" do
      it "does not create a new Stock" do
        expect {
          post :create, params: { stock: invalid_attributes }
        }.not_to change(Stock, :count)
      end

      it "renders a response with 422 status" do
        post :create, params: { stock: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST #refresh_data" do
    it "returns a successful response" do
      post :refresh_data, params: { id: stock.id }
      expect(response).to redirect_to(stock)
    end

    it "calls StockDataFetcher" do
      expect_any_instance_of(StockDataFetcher).to receive(:fetch_recent_data)
      expect_any_instance_of(StockAnalysisService).to receive(:update_historical_data)
      post :refresh_data, params: { id: stock.id }
    end
  end

  describe "GET #day_details" do
    let(:date) { Date.current }
    
    before do
      # Create some predictions for the day
      3.times do
        create(:prediction,
          stock: stock,
          date: date,
          prediction_date: date,
          predicted_price: 100.0,
          actual_price: 101.0
        )
      end
    end

    it "returns a successful response" do
      get :day_details, params: { date: date }
      expect(response).to be_successful
    end

    it "assigns @day" do
      get :day_details, params: { date: date }
      expect(assigns(:day)).to eq(date)
    end

    it "assigns @predictions" do
      get :day_details, params: { date: date }
      expect(assigns(:predictions)).to be_present
      expect(assigns(:predictions).count).to eq(3)
    end
  end
end 