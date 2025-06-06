class Prediction < ApplicationRecord
  belongs_to :stock

  validates :stock_id, presence: true
  validates :prediction_date, presence: true
  validates :predicted_price, presence: true

  def prediction_successful?
    return nil if actual_price.nil?
    
    # Get the price at the time of prediction
    prediction_day_price = stock.historical_prices.find_by(date: prediction_date)&.close
    return nil if prediction_day_price.nil?

    # Calculate price changes
    predicted_change = ((predicted_price - prediction_day_price) / prediction_day_price) * 100
    actual_change = ((actual_price - prediction_day_price) / prediction_day_price) * 100

    # Success criteria: Direction must match (both up or both down)
    (predicted_change > 0) == (actual_change > 0)
  end

  # Alias for date field compatibility
  def date
    prediction_date
  end
  
  # Ensure dates are comparable
  def date=(value)
    self.prediction_date = value
  end
end
