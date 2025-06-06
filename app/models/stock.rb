class Stock < ApplicationRecord
  has_many :stock_prices, dependent: :destroy
  has_many :stock_analyses, dependent: :destroy
  has_many :predictions, dependent: :destroy
  has_many :historical_prices, dependent: :destroy
  has_one :top_stock, dependent: :destroy

  validates :symbol, presence: true, uniqueness: true
  validates :company_name, presence: true

  THRESHOLDS = {
    '1 Week' => 3.0,
    '1 Month' => 5.0,
    '3 Months' => 10.0
  }.freeze

  # ml_score can be nil if not computed yet, default to 1.0 if nil
  def ml_score
    read_attribute(:ml_score) || 1.0
  end

  # Returns a hash indicating whether buying a call option is advisable for each timeframe
  def call_option_recommendations(timeframes = THRESHOLDS.keys)
    Rails.cache.fetch("stock/#{id}/call_option_recommendations", expires_in: 1.hour) do
      recommendations = {}
      current_price = latest_price
  
      return recommendations unless current_price
  
      # Check if predictions are preloaded
      if association(:predictions).loaded?
        predictions_by_date = predictions.index_by(&:prediction_date)
      else
        predictions_by_date = nil
      end
  
      timeframes.each do |timeframe|
        threshold = THRESHOLDS[timeframe]
        next unless threshold
  
        prediction_date = case timeframe
                          when '1 Day'
                            Time.zone.tomorrow
                          when '1 Week'
                            Time.zone.today + 7.days
                          when '1 Month'
                            Time.zone.today + 1.month
                          when '3 Months'
                            Time.zone.today + 3.months
                          end
  
        prediction = if predictions_by_date
                       predictions_by_date[prediction_date]
                     else
                       predictions.find_by(prediction_date: prediction_date)
                     end
  
        next unless prediction && prediction.predicted_price
  
        expected_increase = ((prediction.predicted_price - current_price) / current_price) * 100
  
        recommendations[timeframe] = expected_increase >= threshold
      end
  
      recommendations
    end
  end

  # Cache latest price for 5 minutes
  def latest_price
    Rails.cache.fetch("stock/#{id}/latest_price", expires_in: 5.minutes) do
      stock_prices.order(date: :desc).first&.close || fetch_and_update_current_price
    end
  end

  # Cache predictions for 5 minutes
  def latest_prediction
    Rails.cache.fetch("stock/#{id}/latest_prediction", expires_in: 5.minutes) do
      predictions.order(prediction_date: :desc).first
    end
  end

  def previous_prediction
    Rails.cache.fetch("stock/#{id}/previous_prediction", expires_in: 5.minutes) do
      predictions.order(prediction_date: :desc).second
    end
  end

  def last_prediction_successful?
    Rails.cache.fetch("stock/#{id}/last_prediction_successful", expires_in: 5.minutes) do
      prediction = predictions.order(date: :desc).first
      return nil unless prediction&.actual_price && prediction&.predicted_price

      within_threshold = ((prediction.actual_price - prediction.predicted_price).abs / prediction.predicted_price) < 0.05
      actual_higher_than_predicted = prediction.actual_price > prediction.predicted_price

      within_threshold && actual_higher_than_predicted
    end
  end

  def calculate_future_prediction(target_date)
    Rails.cache.fetch("stock/#{id}/future_prediction/#{target_date}", expires_in: 5.minutes) do
      days_ahead = (target_date - Time.zone.today).to_i
      return nil if days_ahead <= 0

      recent_prices = stock_prices.order(date: :desc).limit(30).pluck(:close)
      return nil if recent_prices.size < 2

      daily_changes = recent_prices.each_cons(2).map { |prev, curr| curr - prev }
      average_daily_change = daily_changes.sum / daily_changes.size

      return nil if latest_price.nil?

      predicted_price = latest_price + (average_daily_change * days_ahead)
      predicted_price.round(2)
    end
  end

  def fetch_and_update_current_price
    fetcher = StockDataFetcher.new(symbol)
    data = fetcher.fetch_recent_data
    return nil unless data

    update!(latest_price: data['c'])
    data['c']
  end

  # Calculates the moving average of the stock's closing prices over the specified number of days
  def moving_average(days)
    today = Time.zone.today
    avg = stock_prices.where('date <= ?', today)
                     .order(date: :desc)
                     .limit(days)
                     .average(:close)
    avg&.to_f
  end

  def calculate_prediction(days_ahead = 1)
    return nil if days_ahead <= 0

    recent_prices = stock_prices.order(date: :desc).limit(30).pluck(:close)
    return nil if recent_prices.size < 2

    # Simple linear regression
    x = (0...recent_prices.size).to_a.reverse
    y = recent_prices

    n = x.size
    sum_x = x.sum
    sum_y = y.sum
    sum_xy = x.zip(y).map { |xi, yi| xi * yi }.sum
    sum_xx = x.map { |xi| xi * xi }.sum

    slope = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)
    intercept = (sum_y - slope * sum_x) / n

    # Predict future price
    future_x = recent_prices.size + days_ahead - 1
    predicted_price = slope * future_x + intercept

    # Ensure prediction is not negative
    [predicted_price, 0].max
  end

  # Class methods for eager loading
  def self.with_latest_prices
    includes(:stock_prices).order('stock_prices.date DESC')
  end

  def self.with_latest_predictions
    includes(:predictions).order('predictions.prediction_date DESC')
  end

  def self.with_historical_prices
    includes(:historical_prices)
  end

  # Batch update method
  def self.update_latest_prices
    find_each do |stock|
      stock.fetch_and_update_current_price
    end
  end
end
