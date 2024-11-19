class AddIndexToHistoricalPricesDate < ActiveRecord::Migration[7.0]
  def change
    add_index :historical_prices, [:stock_id, :date], unique: true
  end
end
