class AddActualPriceToPredictions < ActiveRecord::Migration[7.0]
  def change
    add_column :predictions, :actual_price, :decimal
  end
end
