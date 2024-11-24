class TopStocksFetcher
  include HTTParty
  base_uri 'https://financialmodelingprep.com/api/v3'

  def initialize
    @api_key = Rails.application.credentials.dig(:fmp, :api_key)
  end

  def fetch_top_meme_stocks
    # Fetch the most active stocks
    response = self.class.get('/stock_market/actives', query: {
      apikey: @api_key
    })

    if response.success?
      stocks_data = response.parsed_response

      # Find or create stocks based on the API response
      stocks = stocks_data.map do |stock_data|
        symbol = stock_data['symbol']
        company_name = stock_data['name']

        stock = Stock.find_or_create_by(symbol: symbol) do |s|
          s.company_name = company_name
        end

        # Update latest price
        stock.latest_price = stock_data['price'].to_f
        stock.save!

        stock
      end

      # Filter stocks to include only meme stocks
      meme_stocks = filter_meme_stocks(stocks)

      # Return the top 5 stocks
      meme_stocks.first(5)
    else
      Rails.logger.error "Failed to fetch active stocks: #{response.message}"
      []
    end
  end

  private

  def filter_meme_stocks(stocks)
    # Implement logic to filter meme stocks based on criteria
    # For simplicity, let's assume stocks with high volume and volatility are meme stocks
    stocks.select do |stock|
      # You can define your own criteria here
      stock.latest_price.present? && stock.latest_price > 0
    end
  end
end
