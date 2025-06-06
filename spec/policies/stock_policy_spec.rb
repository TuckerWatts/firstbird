require 'rails_helper'

RSpec.describe StockPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:stock) { create(:stock) }

  permissions :index?, :show? do
    it "allows access to all users" do
      expect(subject).to permit(user, Stock)
      expect(subject).to permit(nil, Stock)
    end
  end

  permissions :create?, :update?, :destroy?, :refresh_data? do
    it "denies access to guest users" do
      expect(subject).not_to permit(nil, Stock)
    end

    it "allows access to logged in users" do
      expect(subject).to permit(user, Stock)
    end
  end

  describe "scope" do
    let!(:stock1) { create(:stock) }
    let!(:stock2) { create(:stock) }
    let!(:stock3) { create(:stock) }
    let(:scope) { Pundit.policy_scope(user, Stock) }

    it "shows all stocks" do
      expect(scope).to include(stock1)
      expect(scope).to include(stock2)
      expect(scope).to include(stock3)
    end
  end
end 