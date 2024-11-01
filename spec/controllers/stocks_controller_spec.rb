require 'rails_helper'

RSpec.describe StocksController, type: :controller do
  let(:stock) { FactoryBot.create(:stock) }
  let!(:prediction) { FactoryBot.create(:prediction, stock: stock) }
  
  before do
    @user = User.create(email: 'test@example.com', password: 'password')
    sign_in @user
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      stock = Stock.create(symbol: "AAPL", company_name: "Apple Inc.")
      get :show, params: { id: stock.id }
      expect(response).to be_successful
    end
  end
end
