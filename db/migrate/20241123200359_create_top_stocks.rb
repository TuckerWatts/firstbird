class CreateTopStocks < ActiveRecord::Migration[7.0]
  def change
    create_table :top_stocks do |t|
      t.references :stock, null: false, foreign_key: true

      t.timestamps
    end
  end
end
