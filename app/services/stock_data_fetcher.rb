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
end
