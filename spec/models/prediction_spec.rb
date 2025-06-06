require 'rails_helper'

RSpec.describe Prediction, type: :model do
  let(:stock) { Stock.create!(company_name: 'Test Stock', symbol: 'TST') }
  let(:prediction_date) { Date.today }
  let(:predicted_price) { 115.0 }
  let(:actual_price) { 110.0 }

  describe 'attributes' do
    it 'has an actual_price attribute' do
      prediction = Prediction.new
      expect(prediction).to respond_to(:actual_price)
    end
  end

  describe '#prediction_successful?' do
    context 'when actual_price is available' do
      let!(:prediction) do
        Prediction.create!(
          stock: stock,
          prediction_date: prediction_date,
          predicted_price: predicted_price,
          actual_price: actual_price
        )
      end

      let!(:historical_price) do
        HistoricalPrice.create!(
          stock: stock,
          date: prediction_date,
          close: 100.0
        )
      end

      it 'returns true if predicted and actual directions match' do
        expect(prediction.prediction_successful?).to be true
      end

      it 'returns false if predicted and actual directions do not match' do
        prediction.update(predicted_price: 90.0)
        expect(prediction.prediction_successful?).to be false
      end
    end

    context 'when actual_price is missing' do
      let!(:prediction) do
        Prediction.create!(
          stock: stock,
          prediction_date: prediction_date,
          predicted_price: predicted_price,
          actual_price: nil
        )
      end

      it 'returns nil' do
        expect(prediction.prediction_successful?).to be_nil
      end
    end
  end
end
