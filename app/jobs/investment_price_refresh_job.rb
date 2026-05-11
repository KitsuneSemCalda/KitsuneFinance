class InvestmentPriceRefreshJob < ApplicationJob
  queue_as :default

  def perform(investment_id)
    investment = Investment.includes(:user).find_by(id: investment_id)
    return unless investment

    investment.refresh_current_price!
  end
end
