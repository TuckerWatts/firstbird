# spec/requests/stocks_spec.rb

require 'rails_helper'

RSpec.describe "Stocks", type: :request do
  let(:stock) { create(:stock, company_name: 'Test Stock', symbol: 'TST') }
  let(:prediction) { create(:prediction, stock: stock) }

  before do
    @user = User.create(email: 'test@example.com', password: 'password')
    sign_in @user
  end

  describe "GET /stocks" do
    it "returns a successful response" do
      get stocks_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Stocks')
    end
  end

  describe 'GET /stocks/:id' do
    context 'when predictions are available' do
      before do
        # Create previous and latest predictions
        @previous_prediction = create(:prediction,
          stock: stock,
          date: Date.yesterday,
          predicted_price: 100.0,
          actual_price: 105.0
        )

        @latest_prediction = create(:prediction,
          stock: stock,
          date: Date.today,
          predicted_price: 110.0,
          actual_price: 115.0
        )

        get stock_path(stock)
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:success)
      end

      it 'displays the stock name and symbol' do
        expect(response.body).to include('Test Stock')
        expect(response.body).to include('TST')
      end

      it 'displays the latest prediction' do
        expect(response.body).to include('Predicted Price')
        expect(response.body).to include('110.0') # Adjust as per your view's formatting
        expect(response.body).to include('Actual Price')
        expect(response.body).to include('115.0') # Adjust as per your view's formatting
      end

      it 'displays the previous prediction' do
        expect(response.body).to include('100.0') # Previous predicted price
        expect(response.body).to include('105.0') # Previous actual price
      end

      it 'indicates the prediction was successful' do
        expect(response.body).to include('The prediction was successful!')
      end
    end

    context 'when predictions are missing' do
      before do
        # Delete existing predictions for this stock
        stock.predictions.delete_all

        get stock_path(stock)
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:success)
      end

      it 'displays a message indicating no predictions are available' do
        expect(response.body).to include('No prediction data available for the previous day.')
      end

      it 'does not display prediction information' do
        expect(response.body).not_to include('Predicted Price')
        expect(response.body).not_to include('Actual Price')
      end
    end
  end
end
