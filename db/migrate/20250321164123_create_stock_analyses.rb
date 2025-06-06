class CreateStockAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_analyses do |t|
      t.date :date
      t.decimal :sentiment_score
      t.decimal :technical_score
      t.decimal :overall_score
      t.references :stock, null: false, foreign_key: true

      t.timestamps
    end
  end
end
