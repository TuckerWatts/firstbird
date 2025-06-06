module Admin
  class DataController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin

    def fetch_data
      Stock.find_each do |stock|
        FetchStockDataJob.perform_later(stock.id)
      end
      redirect_to stocks_path, notice: 'Stock data fetch jobs have been enqueued.'
    end

    private

    def ensure_admin
      unless current_user&.admin?
        redirect_to root_path, alert: 'You are not authorized to access this area.'
      end
    end
  end
end 