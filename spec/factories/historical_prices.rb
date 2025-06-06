FactoryBot.define do
  factory :historical_price do
    stock
    date { Date.current }
    open { 100.0 }
    high { 105.0 }
    low { 95.0 }
    close { 102.0 }
    volume { 1000000 }
  end
end 