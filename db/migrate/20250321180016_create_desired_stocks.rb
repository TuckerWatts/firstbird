class CreateDesiredStocks < ActiveRecord::Migration[8.0]
  def change
    create_table :desired_stocks do |t|
      t.references :stock, null: false, foreign_key: true

      t.timestamps
    end
  end
end
