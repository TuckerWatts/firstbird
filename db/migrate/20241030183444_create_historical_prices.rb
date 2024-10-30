class CreateHistoricalPrices < ActiveRecord::Migration[7.0]
  def change
    create_table :historical_prices do |t|
      t.references :stock, null: false, foreign_key: true
      t.date :date
      t.decimal :open
      t.decimal :high
      t.decimal :low
      t.decimal :close
      t.bigint :volume

      t.timestamps
    end
  end
end
