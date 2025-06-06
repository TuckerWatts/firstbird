class TopStock < ApplicationRecord
  belongs_to :stock

  validates :stock, presence: true
  validates :stock_id, uniqueness: true
end
