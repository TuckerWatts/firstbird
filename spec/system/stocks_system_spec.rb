require 'rails_helper'

RSpec.describe "Stocks", type: :system do
  let(:user) { create(:user) }
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
    driven_by(:rack_test)
    sign_in user
    stub_request(:get, /api.finnhub.io/).to_return(
      status: 200,
      body: api_response.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  it "User views stock with successful prediction" do
    stock = create(:stock)
    prediction = create(:prediction, stock: stock, predicted_price: 160.0, actual_price: 165.0)
    
    visit stock_path(stock)
    
    expect(page).to have_content(stock.company_name)
    expect(page).to have_content(stock.symbol)
    expect(page).to have_content("Prediction was successful")
  end

  it "User views stock with unsuccessful prediction" do
    stock = create(:stock)
    prediction = create(:prediction, stock: stock, predicted_price: 160.0, actual_price: 145.0)
    
    visit stock_path(stock)
    
    expect(page).to have_content(stock.company_name)
    expect(page).to have_content(stock.symbol)
    expect(page).to have_content("Prediction was not successful")
  end

  it "User views stock without actual price" do
    stock = create(:stock)
    prediction = create(:prediction, stock: stock, predicted_price: 160.0, actual_price: nil)
    
    visit stock_path(stock)
    
    expect(page).to have_content(stock.company_name)
    expect(page).to have_content(stock.symbol)
    expect(page).to have_content("Prediction result pending")
  end
end
