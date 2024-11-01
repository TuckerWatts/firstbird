FactoryBot.define do
  factory :stock do
    symbol { "AAPL" }
    company_name { "Apple Inc." }
    sector { "Technology" }
    industry { "Consumer Electronics" }
  end
end
