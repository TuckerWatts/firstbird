class TopStock < ApplicationRecord
  belongs_to :stock

  validates :stock_id, uniqueness: true
end
