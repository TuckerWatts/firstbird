class TopStocksFetcher
  include HTTParty
  base_uri 'https://finnhub.io/api/v1'

  def initialize
    @api_key = Rails.application.credentials.dig(:finnhub, :api_key)
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

      # Filter stocks to include only those with favorable recommendations for timeframes > 1 day
      filtered_stocks = stocks.select do |stock|
        # Ensure predictions are up-to-date
        calculate_and_store_predictions(stock)

        # Get call option recommendations excluding '1 Day'
        timeframes = ['1 Week', '1 Month', '3 Months']
        recommendations = stock.call_option_recommendations(timeframes)

        # Select stocks with at least one favorable recommendation
        recommendations.values.any? { |advisable| advisable }
      end

      # Return the top stocks (e.g., top 5)
      filtered_stocks.first(5)
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

  def calculate_and_store_predictions(stock)
    future_dates = {
      '1 Week' => Time.zone.today + 7.days,
      '1 Month' => Time.zone.today + 1.month,
      '3 Months' => Time.zone.today + 3.months
    }

    future_dates.each do |timeframe, target_date|
      prediction = stock.predictions.find_or_initialize_by(
        date: Time.zone.today,
        prediction_date: target_date
      )
      prediction.prediction_method = 'Moving Averages'
      stock.calculate_future_prediction(target_date) ? prediction.predicted_price = stock.calculate_future_prediction(target_date) : prediction.predicted_price = 0.0
      prediction.actual_price = nil
      prediction.save!
    end
  end
end
