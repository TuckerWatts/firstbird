class AddIndexesForPerformance < ActiveRecord::Migration[8.0]
  def change
    add_index :stocks, :symbol, unique: true, if_not_exists: true
    add_index :stock_prices, [:stock_id, :date], if_not_exists: true
    add_index :predictions, [:stock_id, :prediction_date], if_not_exists: true 
    add_index :historical_prices, [:stock_id, :date], if_not_exists: true
  end
end 