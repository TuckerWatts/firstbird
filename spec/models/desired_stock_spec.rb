require 'rails_helper'

RSpec.describe DesiredStock, type: :model do
  describe 'associations' do
    it { should belong_to(:stock) }
  end

  describe 'validations' do
    it { should validate_presence_of(:stock) }
    
    it 'validates uniqueness of stock_id' do
      stock = create(:stock)
      create(:desired_stock, stock: stock)
      
      duplicate_desired_stock = build(:desired_stock, stock: stock)
      expect(duplicate_desired_stock).not_to be_valid
      expect(duplicate_desired_stock.errors[:stock_id]).to include('has already been taken')
    end
  end
end
