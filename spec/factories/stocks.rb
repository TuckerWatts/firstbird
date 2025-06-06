FactoryBot.define do
  factory :stock do
    sequence(:symbol) { |n| "STOCK#{n}" }
    sequence(:company_name) { |n| "Company #{n}" }
    latest_price { 100.0 }
  end
end
