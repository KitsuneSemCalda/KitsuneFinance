class AutoRenewBudgetsJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.today
    return unless today.day == 1

    prev_month = today.prev_month
    current_month = today.month
    current_year = today.year

    Budget.where(month: prev_month.month, year: prev_month.year).find_each do |prev_budget|
      next if Budget.exists?(
        user_id: prev_budget.user_id,
        category_id: prev_budget.category_id,
        month: current_month,
        year: current_year
      )

      Budget.create!(
        user_id: prev_budget.user_id,
        category_id: prev_budget.category_id,
        month: current_month,
        year: current_year,
        limit_amount: prev_budget.limit_amount
      )
    end
  end
end
