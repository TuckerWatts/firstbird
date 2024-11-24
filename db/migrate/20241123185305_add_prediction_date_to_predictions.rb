class AddPredictionDateToPredictions < ActiveRecord::Migration[7.0]
  def change
    add_column :predictions, :prediction_date, :date
  end
end
