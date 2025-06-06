class StockAnalysisService
  def initialize(stock)
    @stock = stock
    @fetcher = StockDataFetcher.new(stock.symbol)
  end

  def analyze
    Rails.cache.fetch("stock_analysis/#{@stock.id}", expires_in: 1.hour) do
      {
        current_price: @stock.latest_price,
        historical_data: fetch_historical_data,
        predictions: generate_predictions,
        technical_indicators: calculate_technical_indicators,
        risk_metrics: calculate_risk_metrics
      }
    end
  end

  def update_historical_data
    from_date = 1.year.ago.to_date
    to_date = Time.zone.today

    historical_data = @fetcher.fetch_historical_data(from_date, to_date)
    return unless historical_data && historical_data['dates'].present?

    ActiveRecord::Base.transaction do
      historical_data['dates'].each_with_index do |timestamp, index|
        date = Time.zone.at(timestamp).to_date
        next if @stock.historical_prices.exists?(date: date)

        @stock.historical_prices.create!(
          date: date,
          open: historical_data['prices'].try(:[], index) || 0,
          high: historical_data['highs'].try(:[], index) || 0,
          low: historical_data['lows'].try(:[], index) || 0,
          close: historical_data['prices'].try(:[], index) || 0,
          volume: historical_data['volumes'].try(:[], index) || 0
        )
      end
    end
  end

  private

  def fetch_historical_data
    @stock.historical_prices
         .order(date: :desc)
         .limit(30)
         .pluck(:date, :close)
         .to_h
  end

  def generate_predictions
    {
      one_week: @stock.calculate_future_prediction(1.week.from_now.to_date),
      one_month: @stock.calculate_future_prediction(1.month.from_now.to_date),
      three_months: @stock.calculate_future_prediction(3.months.from_now.to_date)
    }
  end

  def calculate_technical_indicators
    prices = @stock.historical_prices.order(date: :desc).limit(30).pluck(:close)
    return {} if prices.size < 2

    {
      sma_20: calculate_sma(prices, 20),
      sma_50: calculate_sma(prices, 50),
      rsi: calculate_rsi(prices),
      macd: calculate_macd(prices)
    }
  end

  def calculate_risk_metrics
    prices = @stock.historical_prices.order(date: :desc).limit(30).pluck(:close)
    return {} if prices.size < 2

    {
      volatility: calculate_volatility(prices),
      beta: calculate_beta(prices),
      sharpe_ratio: calculate_sharpe_ratio(prices)
    }
  end

  def calculate_sma(prices, period)
    return nil if prices.size < period
    prices.first(period).sum / period
  end

  def calculate_rsi(prices, period = 14)
    return nil if prices.size < period + 1

    changes = prices.each_cons(2).map { |prev, curr| curr - prev }
    gains = changes.map { |change| [change, 0].max }
    losses = changes.map { |change| [-change, 0].max }

    avg_gain = gains.first(period).sum / period
    avg_loss = losses.first(period).sum / period

    rs = avg_gain / avg_loss
    100 - (100 / (1 + rs))
  end

  def calculate_macd(prices)
    return nil if prices.size < 26

    ema_12 = calculate_ema(prices, 12)
    ema_26 = calculate_ema(prices, 26)
    macd_line = ema_12 - ema_26
    signal_line = calculate_ema([macd_line], 9)

    {
      macd_line: macd_line,
      signal_line: signal_line,
      histogram: macd_line - signal_line
    }
  end

  def calculate_ema(prices, period)
    multiplier = 2.0 / (period + 1)
    ema = prices.first(period).sum / period

    prices.drop(period).each do |price|
      ema = (price - ema) * multiplier + ema
    end

    ema
  end

  def calculate_volatility(prices)
    returns = prices.each_cons(2).map { |prev, curr| (curr - prev) / prev }
    Math.sqrt(returns.map { |r| (r - returns.mean) ** 2 }.sum / (returns.size - 1))
  end

  def calculate_beta(prices)
    # This is a simplified beta calculation
    # In a real application, you would compare against a market index
    calculate_volatility(prices)
  end

  def calculate_sharpe_ratio(prices)
    returns = prices.each_cons(2).map { |prev, curr| (curr - prev) / prev }
    avg_return = returns.mean
    std_dev = Math.sqrt(returns.map { |r| (r - avg_return) ** 2 }.sum / (returns.size - 1))
    
    risk_free_rate = 0.02 # Assuming 2% risk-free rate
    (avg_return - risk_free_rate) / std_dev
  end
end 