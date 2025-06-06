FactoryBot.define do
  factory :prediction do
    stock
    date { Date.today }
    prediction_date { Date.tomorrow }
    predicted_price { 160.0 }
    actual_price { 165.0 }
    prediction_method { "Moving Averages" }

    after(:build) do |prediction|
      # Only create historical price if it doesn't exist
      unless prediction.stock.historical_prices.exists?(date: prediction.prediction_date)
        create(:historical_price,
          stock: prediction.stock,
          date: prediction.prediction_date,
          close: prediction.actual_price
        )
      end
    end
  end
end
