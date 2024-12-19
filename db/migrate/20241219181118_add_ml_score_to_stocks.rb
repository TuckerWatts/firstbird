class AddMlScoreToStocks < ActiveRecord::Migration[7.0]
  def change
    add_column :stocks, :ml_score, :decimal
  end
end
