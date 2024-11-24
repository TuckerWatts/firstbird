class Prediction < ApplicationRecord
  belongs_to :stock

  validates :date, presence: true
  validates :prediction_date, presence: true  # New attribute
  validates :predicted_price, presence: true
end
