require 'rails_helper'

RSpec.describe "Stocks", type: :feature do
  let!(:stock) { create(:stock, company_name: "Company 8", symbol: "STOCK8") }
  let!(:prediction) { create(:prediction, stock: stock) }

  context "visiting the stocks index" do
    before do
      user = create(:user)
      sign_in user
      visit stocks_path
    end

    scenario "shows the stocks list", js: true do
      # Click the Predictions tab to load the stock predictions
      click_button "Predictions"
      
      # Need to wait for the Turbo Frame to load
      expect(page).to have_selector("turbo-frame#stock_predictions")
      
      # Wait for stock predictions to load
      sleep(1)
      
      # Now we should see the stocks in the stock_predictions frame
      within_frame "stock_predictions" do
        expect(page).to have_content(stock.company_name)
        expect(page).to have_content(stock.symbol)
      end
    end

    scenario "allows editing a stock", js: true do
      # Click the Predictions tab to load the stock predictions
      click_button "Predictions"
      
      # Need to wait for the Turbo Frame to load
      expect(page).to have_selector("turbo-frame#stock_predictions")
      
      # Wait for stock predictions to load
      sleep(1)
      
      # Now we should be able to click edit inside the stock_predictions frame
      within_frame "stock_predictions" do
        within "#stock_#{stock.id}" do
          click_link "Edit"
        end
      end

      expect(page).to have_current_path(edit_stock_path(stock))
      
      # Test the edit form
      fill_in "Company name", with: "Updated Company Name"
      click_button "Update Stock"
      
      # Should be redirected to the stock show page
      expect(page).to have_content("Stock was successfully updated")
      expect(page).to have_content("Updated Company Name")
    end

    scenario "allows deleting a stock", js: true do
      # Click the Predictions tab to load the stock predictions
      click_button "Predictions"
      
      # Need to wait for the Turbo Frame to load
      expect(page).to have_selector("turbo-frame#stock_predictions")
      
      # Wait for stock predictions to load
      sleep(1)
      
      # Now we should be able to delete the stock inside the stock_predictions frame
      accept_confirm do
        within_frame "stock_predictions" do
          within "#stock_#{stock.id}" do
            click_button "Delete"
          end
        end
      end

      expect(page).to have_current_path(stocks_path)
      expect(page).to have_content("Stock was successfully deleted")
    end
  end
end 