# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_11_23_200359) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "historical_prices", force: :cascade do |t|
    t.bigint "stock_id", null: false
    t.date "date"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_id", "date"], name: "index_historical_prices_on_stock_id_and_date", unique: true
    t.index ["stock_id"], name: "index_historical_prices_on_stock_id"
  end

  create_table "predictions", force: :cascade do |t|
    t.bigint "stock_id", null: false
    t.date "date"
    t.decimal "predicted_price"
    t.string "prediction_method"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "actual_price"
    t.decimal "ma_5"
    t.decimal "ma_10"
    t.decimal "ma_20"
    t.date "prediction_date"
    t.index ["stock_id"], name: "index_predictions_on_stock_id"
  end

  create_table "stocks", force: :cascade do |t|
    t.string "symbol"
    t.string "company_name"
    t.string "sector"
    t.string "industry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "latest_price"
  end

  create_table "top_stocks", force: :cascade do |t|
    t.bigint "stock_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_id"], name: "index_top_stocks_on_stock_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "historical_prices", "stocks"
  add_foreign_key "predictions", "stocks"
  add_foreign_key "top_stocks", "stocks"
end
