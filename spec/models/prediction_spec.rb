require 'rails_helper'

RSpec.describe Prediction, type: :model do
  let(:stock) { Stock.create!(name: 'Test Stock', symbol: 'TST') }

  describe 'attributes' do
    it 'has an actual_price attribute' do
      prediction = Prediction.new
      expect(prediction).to respond_to(:actual_price)
    end
  end

  describe '#prediction_successful?' do
    before do
      # Create previous prediction with actual_price
      @previous_prediction = Prediction.create!(
        stock: stock,
        date: Date.yesterday,
        predicted_price: 100.0,
        actual_price: 105.0
      )

      # Create current prediction
      @prediction = Prediction.create!(
        stock: stock,
        date: Date.today,
        predicted_price: 110.0,
        actual_price: 115.0
      )
    end

    context 'when previous actual_price is available' do
      it 'returns true if predicted and actual directions match' do
        expect(@prediction_successful).to be true
      end

      it 'returns false if predicted and actual directions do not match' do
        # Simulate an incorrect prediction
        @prediction.update(actual_price: 95.0)
        expect(@prediction_successful).to be false
      end
    end

    context 'when previous actual_price is missing' do
      it 'returns nil' do
        @previous_prediction.update(actual_price: nil)
        expect(@prediction_successful).to be_nil
      end
    end

    context 'when actual_price is missing' do
      it 'returns nil' do
        @prediction.update(actual_price: nil)
        expect(@prediction_successful).to be_nil
      end
    end
  end
end
