require 'rails_helper'

RSpec.describe TopStock, type: :model do
  describe "associations" do
    it { should belong_to(:stock) }
  end

  describe "validations" do
    let(:stock) { create(:stock) }
    subject { build(:top_stock, stock: stock) }

    it { should validate_presence_of(:stock) }
    it { should validate_uniqueness_of(:stock_id) }
  end

  describe "scopes" do
    let!(:stock1) { create(:stock) }
    let!(:stock2) { create(:stock) }
    let!(:top_stock1) { create(:top_stock, stock: stock1) }
    let!(:top_stock2) { create(:top_stock, stock: stock2) }

    it "returns stocks in order of creation" do
      expect(TopStock.all).to eq([top_stock1, top_stock2])
    end
  end
end
