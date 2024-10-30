class CreatePredictions < ActiveRecord::Migration[7.0]
  def change
    create_table :predictions do |t|
      t.references :stock, null: false, foreign_key: true
      t.date :date
      t.decimal :predicted_price
      t.string :prediction_method

      t.timestamps
    end
  end
end
