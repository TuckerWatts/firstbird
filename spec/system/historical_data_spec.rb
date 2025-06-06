require 'rails_helper'

RSpec.describe "Historical Data", type: :system do
  let(:user) { create(:user) }
  
  before do
    # Use rack_test by default
    driven_by(:rack_test)
    sign_in user
    
    # Create test data for the last 30 days
    (0..29).each do |days_ago|
      date = days_ago.days.ago.to_date
      stock = create(:stock)
      
      # Create predictions with known success rates
      3.times do
        create(:prediction,
          stock: stock,
          date: date,
          prediction_date: date,
          predicted_price: 100.0,
          actual_price: days_ago.even? ? 101.0 : 99.0  # Alternate success/failure
        )
      end
    end
    
    # Clear the cache to ensure fresh data
    Rails.cache.clear
  end

  it "displays the historical data chart and table" do
    visit stocks_path
    
    # Verify table headers
    within('.table-responsive') do
      expect(page).to have_content("Date")
      expect(page).to have_content("Success Rate")
      expect(page).to have_content("Benchmark Rate")
      expect(page).to have_content("Trend")
      expect(page).to have_content("Error Distribution")
    end
    
    # Verify data rows are present
    within('.table-responsive tbody') do
      expect(page).to have_selector('tr', minimum: 25) # Should show last 30 days
    end
  end

  it "allows viewing day details", js: true do
    # Switch to headless Chrome for JS tests
    driven_by(:selenium_chrome_headless)
    visit stocks_path
    
    # Wait for the page to load
    expect(page).to have_content("Daily Prediction Success (Last 30 Days)", wait: 10)
    
    # Click the first "View Details" link
    within('.table-responsive') do
      first("a", text: "View Details").click
    end
    
    # Wait for the day details frame to load
    within_frame "day_details_frame" do
      expect(page).to have_content("Daily Performance Details", wait: 10)
      expect(page).to have_content("Prediction Results")
    end
  end

  it "shows correct trend indicators" do
    visit stocks_path
    
    within('.table-responsive tbody') do
      # Check that trend indicators are present (at least one should be)
      expect(page).to have_selector('td', text: /[↑↓→–]/)
    end
  end

  it "applies correct row colors based on success rate" do
    visit stocks_path
    
    within('.table-responsive tbody') do
      # Check for at least one color-coded row
      expect(page).to have_selector('.table-success, .table-warning, .table-danger')
    end
  end

  it "displays error distribution" do
    visit stocks_path
    
    within('.table-responsive tbody') do
      # Check error distribution format in any row
      expect(page).to have_content(/Low: \d+/)
      expect(page).to have_content(/Med: \d+/)
      expect(page).to have_content(/High: \d+/)
    end
  end

  # Add a specific test for the chart with JS
  it "renders the chart correctly", js: true do
    # Switch to headless Chrome for JS tests
    driven_by(:selenium_chrome_headless)
    visit stocks_path
    
    # Wait for the chart to load
    expect(page).to have_css("canvas[data-daily-success-chart-target='canvas']", wait: 10)
    
    # Check for success rate calculation
    expect(page).to have_selector('script', text: /window\.historicalSuccessRate/, visible: false)
  end
end 