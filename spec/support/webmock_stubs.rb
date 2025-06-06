require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    # Stub Finnhub API quote endpoint
    stub_request(:get, /finnhub.io\/api\/v1\/quote/)
      .to_return(
        status: 200,
        body: {
          c: 150.0,  # Current price
          h: 155.0,  # High price of the day
          l: 145.0,  # Low price of the day
          o: 148.0,  # Open price of the day
          pc: 147.0, # Previous close price
          t: Time.now.to_i
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub Finnhub API company profile endpoint
    stub_request(:get, /finnhub.io\/api\/v1\/stock\/profile2/)
      .to_return(
        status: 200,
        body: {
          name: "Test Company",
          ticker: "TEST",
          marketCapitalization: 1000000,
          shareOutstanding: 1000000,
          industry: "Technology",
          sector: "Information Technology"
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub Finnhub API candles endpoint
    stub_request(:get, /finnhub.io\/api\/v1\/stock\/candle/)
      .to_return(
        status: 200,
        body: {
          c: [150.0, 151.0, 152.0],  # Close prices
          h: [155.0, 156.0, 157.0],  # High prices
          l: [145.0, 146.0, 147.0],  # Low prices
          o: [148.0, 149.0, 150.0],  # Open prices
          s: "ok",  # Status
          t: [Time.now.to_i - 2.days.to_i, Time.now.to_i - 1.day.to_i, Time.now.to_i]  # Timestamps
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end 