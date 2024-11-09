require 'rails_helper'

RSpec.describe "Admins", type: :request do
  describe "GET /fetch_data" do
    it "returns http success" do
      get "/admin/fetch_data"
      expect(response).to have_http_status(:success)
    end
  end

end
