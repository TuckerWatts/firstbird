class StockDataFetcher
  include HTTParty
  base_uri 'https://finnhub.io/api/v1'

  def initialize(stock_symbol)
    @stock_symbol = stock_symbol
    @api_key = Rails.application.credentials.dig(:finnhub, :api_key)
  end

  def fetch_recent_data
    response = self.class.get("/quote/#{@stock_symbol}", query: {
      apikey: @api_key
    })

    parsed_response = response.parsed_response

    if response.success? && parsed_response.is_a?(Array) && parsed_response.any?
      data = parsed_response.first

      {
        current_price: data['price'].to_f,
        high_price: data['dayHigh'].to_f,
        low_price: data['dayLow'].to_f,
        open_price: data['open'].to_f,
        previous_close_price: data['previousClose'].to_f,
        timestamp: Time.at(data['timestamp'].to_i)
      }
    else
      error_message = parsed_response.is_a?(Hash) ? parsed_response['Error Message'] || parsed_response['message'] : "Invalid response format"
      Rails.logger.error "Failed to fetch recent data for #{@stock_symbol}: #{error_message}"
      nil
    end
  end

  def fetch_historical_prices(days)
    response = self.class.get("/historical-price-full/#{@stock_symbol}", query: {
      timeseries: days,
      apikey: @api_key
    })

    parsed_response = response.parsed_response

    if response.success? && parsed_response.is_a?(Hash) && parsed_response['historical']
      data = parsed_response['historical']

      if data.is_a?(Array)
        data.map do |entry|
          {
            date: Date.parse(entry['date']),
            open: entry['open'].to_f,
            high: entry['high'].to_f,
            low: entry['low'].to_f,
            close: entry['close'].to_f, # Key is :close
            volume: entry['volume'].to_i
          }
        end
      else
        Rails.logger.error "Expected 'historical' to be an Array, got #{data.class}. Response: #{parsed_response.inspect}"
        []
      end
    else
      error_message = parsed_response.is_a?(Hash) ? parsed_response['Error Message'] || parsed_response['message'] : "Invalid response format"
      Rails.logger.error "Failed to fetch historical data for #{@stock_symbol}: #{error_message}. Response: #{parsed_response.inspect}"
      []
    end
  end
end
