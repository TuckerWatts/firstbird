require 'rails_helper'

RSpec.describe Stock, type: :model do  
  it "is valid with valid attributes" do
    stock = Stock.new(symbol: "AAPL", company_name: "Apple Inc.")
    expect(stock).to be_valid
  end

  it "is not valid without a symbol" do
    stock = Stock.new(company_name: "Apple Inc.")
    expect(stock).not_to be_valid
  end
end
