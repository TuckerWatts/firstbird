require 'rails_helper'

RSpec.describe "admin/fetch_data", type: :view do
  let(:user) { create(:user, admin: true) }

  before do
    sign_in user
    render template: "admin/fetch_data"
  end

  it "displays the fetch data header" do
    expect(rendered).to have_content("Fetch Stock Data")
  end

  it "displays the fetch data button" do
    expect(rendered).to have_button("Fetch Data")
  end

  it "displays the back to stocks link" do
    expect(rendered).to have_link("Back to Stocks", href: stocks_path)
  end

  it "displays the explanation text" do
    expect(rendered).to have_content("This will fetch the latest data for all stocks")
  end
end
