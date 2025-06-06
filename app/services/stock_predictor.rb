class StockPredictor
  def initialize(stock)
    @stock = stock
  end

  def moving_average(days = 5)
    # Use fetch_historical_prices to retrieve data from the local DB, optionally calling /quote once if today's data is missing
    fetcher = StockDataFetcher.new(@stock.symbol)
    historical_data = fetcher.fetch_historical_prices(@stock, days + 1)

    return nil if historical_data.size < (days + 1)

    # Sort data by date in descending order
    sorted_data = historical_data.sort_by { |entry| entry[:date] }.reverse

    # Exclude the latest day if it's today (market may not have closed yet)
    if sorted_data.first[:date] == Date.today
      relevant_data = sorted_data[1..days]
    else
      relevant_data = sorted_data[0...days]
    end

    prices = relevant_data.map { |data| data[:close] }.compact

    if prices.size < days
      Rails.logger.error "Not enough valid close prices for #{@stock.symbol}. Required: #{days}, Available: #{prices.size}"
      return nil
    end

    average_price = prices.sum / days.to_f

    prediction_date = Date.today

    prediction = @stock.predictions.find_or_initialize_by(
      date: prediction_date,
      prediction_method: "Moving Average (#{days} days)"
    )

    prediction.predicted_price = average_price
    prediction.actual_price = sorted_data.first[:close]
    prediction.prediction_date = Date.tomorrow
    prediction.save!
  end
end
