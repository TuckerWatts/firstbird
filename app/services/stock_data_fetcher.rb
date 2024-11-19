class StockDataFetcher
  include HTTParty
  base_uri 'https://financialmodelingprep.com/api/v3'

  def initialize(stock_symbol)
    @stock_symbol = stock_symbol
    @api_key = Rails.application.credentials.dig(:fmp, :api_key)
  end

  def fetch_recent_data
    response = self.class.get("/quote/#{@stock_symbol}", query: {
      apikey: @api_key
    })

    if response.success? && response.parsed_response.is_a?(Array) && response.parsed_response.any?
      data = response.parsed_response.first

      {
        current_price: data['price'].to_f,
        high_price: data['dayHigh'].to_f,
        low_price: data['dayLow'].to_f,
        open_price: data['open'].to_f,
        previous_close_price: data['previousClose'].to_f,
        timestamp: Time.at(data['timestamp'].to_i)
      }
    else
      Rails.logger.error "Failed to fetch data for #{@stock_symbol}"
      nil
    end
  end

  def fetch_historical_prices(days)
    response = self.class.get('/time_series', query: {
      symbol: @stock_symbol,
      interval: '1day',
      outputsize: days,
      apikey: @api_key
    })

    if response.success? && response.parsed_response['status'] != 'error'
      data = response.parsed_response['values']
      data.map do |entry|
        {
          date: Date.parse(entry['datetime']),
          open: entry['open'].to_f,
          high: entry['high'].to_f,
          low: entry['low'].to_f,
          close: entry['close'].to_f,
          volume: entry['volume'].to_i
        }
      end
    else
      error_message = response.parsed_response['message'] || "HTTP #{response.code}"
      Rails.logger.error "Failed to fetch historical data for #{@stock_symbol}: #{error_message}"
      []
    end
  end
end
