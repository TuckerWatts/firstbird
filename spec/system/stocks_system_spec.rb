require 'rails_helper'

RSpec.feature 'Stocks', type: :feature do
  let(:stock) { Stock.create!(name: 'Test Stock', symbol: 'TST') }

  scenario 'User views stock with successful prediction' do
    # Create predictions
    Prediction.create!(
      stock: stock,
      date: Date.yesterday,
      predicted_price: 100.0,
      actual_price: 105.0
    )

    visit stock_path(stock)

    expect(page).to have_content('The prediction was successful!')
    expect(page).to have_css('.text-success')
  end

  scenario 'User views stock with unsuccessful prediction' do
    # Create predictions
    Prediction.create!(
      stock: stock,
      date: Date.yesterday,
      predicted_price: 100.0,
      actual_price: 95.0
    )

    visit stock_path(stock)

    expect(page).to have_content('The prediction was not successful.')
    expect(page).to have_css('.text-danger')
  end

  scenario 'User views stock without actual price' do
    # Create prediction without actual_price
    Prediction.create!(
      stock: stock,
      date: Date.yesterday,
      predicted_price: 100.0,
      actual_price: nil
    )

    visit stock_path(stock)

    expect(page).to have_content('Cannot determine prediction success yet.')
    expect(page).to have_css('.text-warning')
  end
end
