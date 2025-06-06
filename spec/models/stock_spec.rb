require 'rails_helper'

RSpec.describe Stock, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:company_name) }
    it { should validate_uniqueness_of(:symbol) }
  end

  describe 'associations' do
    it { should have_many(:stock_prices) }
    it { should have_many(:stock_analyses) }
  end

  it "is valid with valid attributes" do
    stock = Stock.new(symbol: "AAPL", company_name: "Apple Inc.")
    expect(stock).to be_valid
  end

  it "is not valid without a symbol" do
    stock = Stock.new(company_name: "Apple Inc.")
    expect(stock).not_to be_valid
  end
end
