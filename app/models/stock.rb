class Stock < ApplicationRecord
  has_many :historical_prices, dependent: :destroy
  has_many :predictions, dependent: :destroy

  validates :symbol, presence: true

  # Returns the latest prediction for the stock
  def latest_prediction
    # Use preloaded predictions and sort in Ruby
    @latest_prediction ||= predictions.max_by(&:date)
  end

  def previous_prediction
    return nil unless latest_prediction
    @previous_prediction ||= predictions.select { |p| p.date < latest_prediction.date }.max_by(&:date)
  end

  def prediction_successful?
    return nil unless previous_prediction && previous_prediction.actual_price && previous_prediction.predicted_price

    # Find previous actual price from preloaded predictions
    prior_prediction = predictions.select { |p| p.date < previous_prediction.date }.max_by(&:date)
    previous_actual_price = prior_prediction&.actual_price

    return nil unless previous_actual_price

    predicted_direction = previous_prediction.predicted_price - previous_actual_price
    actual_direction = previous_prediction.actual_price - previous_actual_price

    (predicted_direction * actual_direction) > 0
  end

  def moving_average(days)
    prices = historical_prices.where('date <= ?', Date.today).order(date: :desc).limit(days)
    return nil if prices.size < days

    total = prices.sum(:close)
    (total / days).round(2)
  end
end
