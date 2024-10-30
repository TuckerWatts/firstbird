class CreateStocks < ActiveRecord::Migration[7.0]
  def change
    create_table :stocks do |t|
      t.string :symbol
      t.string :company_name
      t.string :sector
      t.string :industry

      t.timestamps
    end
  end
end
