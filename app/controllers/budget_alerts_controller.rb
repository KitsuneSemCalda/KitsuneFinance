class BudgetAlertsController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard"

  def index
    @page_title = "Alertas de Orçamento"
    @budgets = current_user.budgets.where(month: Date.today.month, year: Date.today.year).includes(:category)

    spent_by_category = current_user.transactions.expense
      .where(date: Date.today.beginning_of_month..Date.today.end_of_month)
      .group(:category_id)
      .sum(:amount)

    @alerts = @budgets.select { |b| spent_by_category[b.category_id].to_i >= (b.limit_amount * 0.8) }
  end
end
