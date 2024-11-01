class GenerateStockPredictionsJob < ApplicationJob
  queue_as :default

  def perform(stock_id)
    stock = Stock.find(stock_id)
    predictor = StockPredictor.new(stock)
    predictor.moving_average(5)
    predictor.moving_average(10)
    predictor.moving_average(20)
  end
end
