class StockPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    user.present?
  end

  def destroy?
    user.present?
  end

  def refresh_data?
    user.present?
  end

  def refresh_top_stocks?
    user.present?
  end

  def day_details?
    true
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end 