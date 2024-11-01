class StocksController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @stocks = Stock.all
  end

  def show
    @stock = Stock.find(params[:id])
    @historical_prices = @stock.historical_prices.order(date: :desc).limit(100)
    @predictions = @stock.predictions.order(date: :desc)
  end
end
