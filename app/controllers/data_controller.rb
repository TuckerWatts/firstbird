class DataController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def fetch_data
    Stock.find_each do |stock|
      FetchStockDataJob.perform_later(stock.id)
      GenerateStockPredictionsJob.perform_later(stock.id)
    end

    flash[:notice] = "Stock data fetching and predictions generation have been started."
    redirect_to root_path
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "You are not authorized to perform this action."
    end
  end
end
