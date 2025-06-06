class StockDataFetcher
  include HTTParty
  base_uri 'https://finnhub.io/api/v1'

  def initialize(symbol)
    @symbol = symbol
    @api_key = Rails.application.credentials.finnhub[:api_key]
  end

  def fetch_recent_data
    Rails.cache.fetch("stock_data/#{@symbol}/recent", expires_in: 5.minutes) do
      response = self.class.get("/quote", query: {
        symbol: @symbol,
        token: @api_key
      })

      return nil unless response.success? && response.parsed_response['c'].present?

      response.parsed_response
    end
  end

  def fetch_historical_data(from_date, to_date)
    cache_key = "stock_data/#{@symbol}/historical/#{from_date.to_date}/#{to_date.to_date}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      response = self.class.get("/stock/candle", query: {
        symbol: @symbol,
        from: from_date.to_time.to_i,
        to: to_date.to_time.to_i,
        resolution: 'D',
        token: @api_key
      })

      return nil unless response.success? && response.parsed_response['c'].present?

      process_historical_data(response.parsed_response)
    end
  end

  def fetch_historical_prices(stock, days)
    # We need days+1 entries (including potentially today's data)
    required_count = days + 1

    # Check local historical_prices first
    prices = stock.historical_prices.order(date: :desc).limit(required_count).map do |hp|
      {
        date: hp.date,
        open: hp.open,
        high: hp.high,
        low: hp.low,
        close: hp.close,
        volume: hp.volume
      }
    end

    # If we don't have enough data and we haven't recorded today's price, try fetching today's data once.
    if prices.size < required_count
      # Check if we have today's record
      if !stock.historical_prices.exists?(date: Date.today)
        # Fetch today's price once
        data = fetch_recent_data
        if data && data['price']
          stock.historical_prices.create!(
            date: Date.today,
            open: data['open'] || data['price'],
            high: data['high'] || data['price'],
            low: data['low'] || data['price'],
            close: data['price'],
            volume: 0
          )
        else
          Rails.logger.error "Could not fetch today's price for #{@symbol}, no additional data stored."
        end
      end

      # Requery after attempting to add today's data
      prices = stock.historical_prices.order(date: :desc).limit(required_count).map do |hp|
        {
          date: hp.date,
          open: hp.open,
          high: hp.high,
          low: hp.low,
          close: hp.close,
          volume: hp.volume
        }
      end
    end

    prices
  end

  def self.update_ml_scores
    # Fetch all stocks
    stocks = Stock.includes(:historical_prices).to_a

    # Ensure minimal data presence (latest_price)
    stocks.each do |stock|
      if stock.latest_price.nil?
        stock.fetch_and_update_current_price rescue nil
      end
    end

    # Compute ml_score for each stock using what data we have
    stocks.each do |stock|
      ml_score = compute_ml_score_for(stock)
      stock.update!(ml_score: ml_score)
    end
  end

  def self.compute_ml_score_for(stock)
    volatility = calculate_volatility(stock)
    timeframe = Time.zone.today + 7.days
    predicted_growth = calculate_predicted_growth(stock, timeframe)

    base_score = 1.0
    volatility_factor = map_volatility_to_range(volatility, 0.0, 5.0, 0.5, 1.5)
    growth_bonus = (predicted_growth / 100.0) * 0.5

    ml_score = base_score * volatility_factor + growth_bonus
    ml_score.clamp(0.5, 1.5)
  end

  def self.calculate_volatility(stock)
    closes = stock.historical_prices.order(date: :desc).limit(30).pluck(:close)
    return 0.0 if closes.size < 2

    daily_returns = closes.each_cons(2).map { |y, t| ((t - y) / y) * 100.0 }
    mean = daily_returns.sum / daily_returns.size
    variance = daily_returns.map { |r| (r - mean)**2 }.sum / daily_returns.size
    Math.sqrt(variance)
  end

  def self.calculate_predicted_growth(stock, timeframe)
    predicted_price = stock.calculate_future_prediction(timeframe)
    return 0.0 if predicted_price.nil? || stock.latest_price.nil?

    ((predicted_price - stock.latest_price) / stock.latest_price) * 100.0
  end

  def self.map_volatility_to_range(value, old_min, old_max, new_min, new_max)
    return new_min if old_max == old_min

    ratio = (value - old_min) / (old_max - old_min)
    new_value = new_min + ratio * (new_max - new_min)
    new_value.clamp(new_min, new_max)
  end

  def self.fetch_multiple_stocks(symbols)
    symbols.each_slice(10) do |batch|
      batch.each do |symbol|
        new(symbol).fetch_recent_data
      end
      sleep(0.5) # Rate limiting
    end
  end

  private

  def process_historical_data(data)
    {
      'dates' => data['t'],
      'prices' => data['c'],
      'volumes' => data['v'],
      'highs' => data['h'],
      'lows' => data['l']
    }
  end
end
