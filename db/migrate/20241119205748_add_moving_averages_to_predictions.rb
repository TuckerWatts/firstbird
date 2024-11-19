class AddMovingAveragesToPredictions < ActiveRecord::Migration[7.0]
  def change
    add_column :predictions, :ma_5, :decimal
    add_column :predictions, :ma_10, :decimal
    add_column :predictions, :ma_20, :decimal
  end
end
