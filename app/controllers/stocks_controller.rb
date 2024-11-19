class StocksController < ApplicationController

  def index
    @stocks = Stock.includes(:predictions)
  end

  def show
    @stock = Stock.find(params[:id])

    @historical_prices = @stock.historical_prices.order(date: :desc).limit(100)

    @latest_prediction = @stock.predictions.order(date: :desc).first

    if @latest_prediction
      # Fetch the previous day's prediction
      @previous_prediction = @stock.predictions.where("date < ?", @latest_prediction.date).order(date: :desc).first

      # Determine if the previous prediction was successful
      if @previous_prediction
        @prediction_successful = prediction_successful?(@previous_prediction)
      else
        @prediction_successful = nil
      end
    else
      # No predictions available
      @previous_prediction = nil
      @prediction_successful = nil
    end
  end

  private

  def prediction_successful?(prediction)
    previous_prediction = @stock.predictions.where("date <= ?", prediction.date).order(date: :desc).first

    if previous_prediction && prediction.actual_price && previous_prediction.actual_price
      predicted_direction = prediction.predicted_price - previous_prediction.actual_price
      actual_direction = prediction.actual_price - previous_prediction.actual_price
      (predicted_direction * actual_direction) > 0
    else
      nil
    end
  end
end
