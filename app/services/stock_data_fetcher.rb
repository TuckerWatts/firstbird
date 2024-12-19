class StockDataFetcher
  include HTTParty
  base_uri 'https://finnhub.io/api/v1'

  def initialize(stock_symbol)
    @stock_symbol = stock_symbol
    @api_key = Rails.application.credentials.dig(:finnhub, :api_key)
  end

  def fetch_recent_data
    response = self.class.get('/quote', query: {
      symbol: @stock_symbol,
      token: @api_key
    })

    parsed_response = response.parsed_response

    if response.success? && parsed_response.is_a?(Hash) && parsed_response['c']
      # 'c' = current price, 'h' = high, 'l' = low, 'o' = open, 'pc' = previous close
      {
        'symbol' => @stock_symbol,
        'price' => parsed_response['c'].to_f,
        'name' => @stock_symbol, # Finnhub doesn't provide name here; consider another endpoint or cached value.
        'high' => parsed_response['h'].to_f,
        'low' => parsed_response['l'].to_f,
        'open' => parsed_response['o'].to_f,
        'previous_close' => parsed_response['pc'].to_f
      }
    else
      error_message = parsed_response.is_a?(Hash) && parsed_response['error'] ? parsed_response['error'] : "Invalid response format"
      Rails.logger.error "Failed to fetch recent data for #{@stock_symbol}: #{error_message}"
      nil
    end
  end

  def fetch_historical_data
    # Fetch 1 year of daily data as an example
    to = Time.now.to_i
    from = (Time.now - 365 * 24 * 60 * 60).to_i

    response = self.class.get('/stock/candle', query: {
      symbol: @stock_symbol,
      resolution: 'D',
      from: from,
      to: to,
      token: @api_key
    })

    parsed_response = response.parsed_response

    if response.success? && parsed_response.is_a?(Hash) && parsed_response['s'] == 'ok'
      timestamps = parsed_response['t']
      opens = parsed_response['o']
      highs = parsed_response['h']
      lows = parsed_response['l']
      closes = parsed_response['c']
      volumes = parsed_response['v']

      timestamps.each_with_index.map do |timestamp, i|
        {
          'date' => Time.at(timestamp).to_date,
          'open' => opens[i].to_f,
          'high' => highs[i].to_f,
          'low' => lows[i].to_f,
          'close' => closes[i].to_f,
          'volume' => volumes[i].to_i
        }
      end
    else
      error_message = parsed_response.is_a?(Hash) && parsed_response['error'] ? parsed_response['error'] : "Invalid response format or s != ok"
      Rails.logger.error "Failed to fetch historical data for #{@stock_symbol}: #{error_message}"
      nil
    end
  end

  def update_ml_scores
    # Fetch all stocks
    stocks = Stock.includes(:historical_prices, :predictions).to_a

    # Ensure we have the necessary data for calculations
    # For example, ensure historical_prices and latest_price are present
    stocks.each do |stock|
      if stock.latest_price.nil?
        stock.fetch_and_update_current_price rescue nil
      end
      if stock.historical_prices.empty?
        stock.fetch_and_update_historical_prices rescue nil
      end
    end

    # Compute ml_score for each stock using a more meaningful heuristic
    stocks.each do |stock|
      ml_score = compute_ml_score_for(stock)
      stock.update!(ml_score: ml_score)
    end
  end

  private

  private

  def compute_ml_score_for(stock)
    # Calculate volatility from recent historical prices
    volatility = calculate_volatility(stock)

    # Calculate short-term predicted growth (e.g., 1 week ahead)
    timeframe = Time.zone.today + 7.days
    predicted_growth = calculate_predicted_growth(stock, timeframe)

    # Combine both into a final score
    # Start with a baseline of 1.0
    # Adjust by volatility factor and predicted growth factor
    # Just a simple formula for demonstration:
    base_score = 1.0
    # Increase score by (volatility_factor - 1.0) to shift it around baseline
    # volatility_factor is mapped from volatility (0.0 to high) to a range around [0.5..1.5]
    volatility_factor = map_volatility_to_range(volatility, 0.0, 5.0, 0.5, 1.5)

    # predicted_growth is a percentage (e.g., if predicted to grow 10%, predicted_growth = 10.0)
    # We convert that into a small bonus: e.g., add (predicted_growth / 100 * 0.5)
    # so a 10% predicted growth adds 0.05 to the score.
    growth_bonus = (predicted_growth / 100.0) * 0.5

    # Final score
    ml_score = base_score * volatility_factor + growth_bonus

    # Clamp ml_score between 0.5 and 1.5 to avoid extreme values
    ml_score = ml_score.clamp(0.5, 1.5)

    ml_score
  end

  def calculate_volatility(stock)
    closes = stock.historical_prices.order(date: :desc).limit(30).pluck(:close)
    return 0.0 if closes.size < 2

    daily_returns = closes.each_cons(2).map { |y, t| ((t - y) / y) * 100.0 }
    mean = daily_returns.sum / daily_returns.size
    variance = daily_returns.map { |r| (r - mean)**2 }.sum / daily_returns.size
    stddev = Math.sqrt(variance)
    stddev
  end

  def calculate_predicted_growth(stock, timeframe)
    predicted_price = stock.calculate_future_prediction(timeframe)
    return 0.0 if predicted_price.nil? || stock.latest_price.nil?

    ((predicted_price - stock.latest_price) / stock.latest_price) * 100.0
  end

  def map_volatility_to_range(value, old_min, old_max, new_min, new_max)
    # If no volatility or only one data point, return baseline
    return new_min if old_max == old_min

    # Normalize value within old_min to old_max and scale to new range
    ratio = (value - old_min) / (old_max - old_min)
    new_value = new_min + ratio * (new_max - new_min)

    # If volatility is low, new_value ~ new_min (0.5)
    # If volatility is high, new_value ~ new_max (1.5)
    # For large volatility, cap at new_max
    new_value = new_value.clamp(new_min, new_max)
    new_value
  end
end
