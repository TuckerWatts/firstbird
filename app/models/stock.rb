class Stock < ApplicationRecord
  has_many :historical_prices, dependent: :destroy
  has_many :predictions, dependent: :destroy

  has_one :top_stock, dependent: :destroy

  validates :symbol, presence: true

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

  def calculate_future_prediction(target_date)
    @prediction_cache ||= {}
    return @prediction_cache[target_date] if @prediction_cache.key?(target_date)

    days_ahead = (target_date - Time.zone.today).to_i
    if days_ahead <= 0
      @prediction_cache[target_date] = nil
      return nil
    end

    recent_prices = historical_prices.order(date: :desc).limit(30).pluck(:close)
    if recent_prices.size < 2
      Rails.logger.warn("Not enough historical data for #{symbol}.")
      @prediction_cache[target_date] = nil
      return nil
    end

    daily_changes = recent_prices.each_cons(2).map { |prev, curr| curr - prev }
    average_daily_change = daily_changes.sum / daily_changes.size

    if latest_price.nil?
      Rails.logger.warn("Latest price is missing for #{symbol}.")
      @prediction_cache[target_date] = nil
      return nil
    end

    predicted_price = latest_price + (average_daily_change * days_ahead)
    @prediction_cache[target_date] = predicted_price.round(2)
  end

  def fetch_and_update_current_price
    fetcher = StockDataFetcher.new(symbol)
    data = fetcher.fetch_recent_data
    if data && data['price']
      self.latest_price = data['price'].to_f
      self.company_name ||= data['name']
      save!
    else
      Rails.logger.error "Failed to fetch recent data for #{symbol} or no price found."
    end
  end

  def latest_price
    super || fetch_and_update_current_price
  end

  # def calculate_future_prediction(target_date)
  #   days_ahead = (target_date - Time.zone.today).to_i
  #   return nil if days_ahead <= 0
  #
  #   recent_prices = historical_prices.order(date: :desc).limit(30).pluck(:close)
  #   return nil if recent_prices.size < 2
  #
  #   daily_changes = recent_prices.each_cons(2).map { |yesterday, today| today - yesterday }
  #   average_daily_change = daily_changes.sum / daily_changes.size
  #
  #   predicted_price = latest_price + (average_daily_change * days_ahead)
  #   predicted_price.round(2)
  # end

  # Returns the latest prediction, utilizing preloaded associations if available
  def latest_prediction
    if association(:predictions).loaded?
      predictions.max_by(&:date)
    else
      predictions.order(date: :desc).first
    end
  end

  # Returns the prediction immediately before the latest one
  def previous_prediction
    latest = latest_prediction
    return nil unless latest

    if association(:predictions).loaded?
      earlier_predictions = predictions.select { |p| p.date < latest.date }
      earlier_predictions.max_by(&:date)
    else
      predictions.where("date < ?", latest.date).order(date: :desc).first
    end
  end

  # Determines if the last prediction was successful
  def last_prediction_successful?
    latest = latest_prediction
    previous = previous_prediction

    if latest && previous && latest.actual_price.present? && previous.actual_price.present? && latest.predicted_price.present?
      predicted_direction = latest.predicted_price - previous.actual_price
      actual_direction = latest.actual_price - previous.actual_price

      # Returns true if the predicted direction matches the actual direction
      (predicted_direction * actual_direction) > 0
    else
      nil
    end
  end

  # Calculates the moving average of the stock's closing prices over the specified number of days
  def moving_average(days)
    today = Time.zone.today
    avg = historical_prices.where('date <= ?', today)
                           .order(date: :desc)
                           .limit(days)
                           .average(:close)
    avg&.round(2)
  end
end
