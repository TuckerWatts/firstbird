class StockPredictor
  def initialize(stock)
    @stock = stock
  end

  def moving_average(days = 5)
    prices = @stock.historical_prices.order(date: :desc).limit(days).pluck(:close)
    return nil if prices.size < days

    average_price = prices.sum / days.to_f

    # Create a prediction for the next day
    prediction_date = Date.today + 1.day
    Prediction.create(
      stock: @stock,
      date: prediction_date,
      predicted_price: average_price,
      prediction_method: "Moving Average (#{days} days)"
    )
  end

end
