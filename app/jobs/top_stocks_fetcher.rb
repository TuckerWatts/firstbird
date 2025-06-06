class TopStocksFetcher
  def initialize
    @api_key = Rails.application.credentials.dig(:finnhub, :api_key)
  end

  def fetch_top_meme_stocks
    timeframe = Time.zone.today + 7.days  # Short-term prediction: 1 week
    all_stocks = Stock.includes(:historical_prices).to_a

    # Ensure data is up-to-date for each stock
    all_stocks.each do |stock|
      update_stock_data(stock)
      calculate_and_store_prediction(stock, timeframe)
    end

    # Compute a composite "meme score" for each stock
    scores = {}
    all_stocks.each do |stock|
      predicted_price = stock.calculate_future_prediction(timeframe)
      scores[stock.id] = calculate_composite_score(stock, predicted_price, timeframe)
    end

    # Sort by composite score and pick top 5
    top_stocks = all_stocks.sort_by { |stock| scores[stock.id] }.reverse.first(5)
    top_stocks
  end

  private

  def update_stock_data(stock)
    if stock.latest_price.nil?
      stock.fetch_and_update_current_price rescue nil
    end

    if stock.historical_prices.empty?
      stock.fetch_and_update_historical_prices rescue nil
    end
  end

  def calculate_and_store_prediction(stock, target_date)
    prediction = stock.predictions.find_or_initialize_by(
      date: Time.zone.today,
      prediction_date: target_date
    )
    prediction.prediction_method = 'Moving Averages'
    predicted_price = stock.calculate_future_prediction(target_date)
    prediction.predicted_price = predicted_price || 0.0
    prediction.actual_price = nil
    prediction.save!
  end

  def calculate_composite_score(stock, predicted_price, timeframe)
    return -Float::INFINITY if predicted_price.nil? || stock.latest_price.nil?

    # 1. Predicted Gain Percentage
    predicted_gain = ((predicted_price - stock.latest_price) / stock.latest_price) * 100.0

    # 2. Volatility: Based on recent price changes standard deviation
    volatility = calculate_volatility(stock)

    # 3. Volume Spike: Ratio of today's volume vs. average volume
    volume_spike = calculate_volume_spike(stock)

    # 4. ML Score: Assume stock has an ml_score attribute; default to 1.0 if none
    ml_score = stock.ml_score || 1.0

    # Composite score:
    # Heuristics (example weights):
    # - Predicted gain: 0.7 weight
    # - Volatility: 0.2 weight (higher volatility = more meme-like)
    # - Volume spike: 0.1 weight
    # - Multiply result by ml_score as a factor

    base_score = (predicted_gain * 0.7) + (volatility * 0.2) + (volume_spike * 0.1)
    composite_score = base_score * ml_score
    composite_score
  end

  def calculate_volatility(stock)
    # Get recent close prices
    closes = stock.historical_prices.order(date: :desc).limit(30).pluck(:close)
    return 0.0 if closes.size < 2

    daily_returns = closes.each_cons(2).map { |y, t| (t - y) / y * 100.0 }
    mean = daily_returns.sum / daily_returns.size
    variance = daily_returns.map { |r| (r - mean)**2 }.sum / daily_returns.size
    stddev = Math.sqrt(variance)

    # Higher stddev means more volatility
    stddev
  end

  def calculate_volume_spike(stock)
    volumes = stock.historical_prices.order(date: :desc).limit(30).pluck(:volume)
    return 0.0 if volumes.empty?

    today_volume = volumes.first
    avg_volume = volumes.sum / volumes.size

    return 0.0 if avg_volume == 0

    # Volume spike ratio
    (today_volume / avg_volume.to_f)
  end
end
