class StockDataFetcher
  include HTTParty
  base_uri 'https://www.alphavantage.co'

  def initialize(stock_symbol)
    @stock_symbol = stock_symbol
    @api_key = Rails.application.credentials.dig(:alpha_vantage, :api_key)

  end

  def fetch_daily_adjusted
    response = self.class.get('/query', query: {
      function: 'TIME_SERIES_DAILY_ADJUSTED',
      symbol: @stock_symbol,
      outputsize: 'full',
      apikey: @api_key
    })

    if response.success?
      parse_response(response)
    else
      Rails.logger.error "Failed to fetch data for #{@stock_symbol}: #{response.code}"
      nil
    end
  end

  private

  def parse_response(response)
    time_series = response['Time Series (Daily)']
    return unless time_series

    historical_prices = []

    time_series.each do |date_str, data|
      date = Date.parse(date_str)
      open_price = data['1. open'].to_f
      high_price = data['2. high'].to_f
      low_price = data['3. low'].to_f
      close_price = data['4. close'].to_f
      volume = data['6. volume'].to_i

      historical_prices << {
        date: date,
        open: open_price,
        high: high_price,
        low: low_price,
        close: close_price,
        volume: volume
      }
    end

    historical_prices
  end
end
