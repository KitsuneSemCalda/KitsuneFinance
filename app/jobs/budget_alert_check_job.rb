class BudgetAlertCheckJob < ApplicationJob
  queue_as :default

  def perform
    Budget.find_each do |budget|
      spent = budget.spent_amount
      limit = budget.limit_amount
      next if limit.zero?

      pct = (spent / limit) * 100

      if pct >= 100 && budget.alert_100_sent_at.nil?
        Rails.logger.warn "[BUDGET ALERT] User##{budget.user_id} — Categoria##{budget.category_id} " \
                          "excedeu 100% do orçamento (#{spent} de #{limit})"
        budget.update!(alert_100_sent_at: Time.current)
      end

      if pct >= 80 && pct < 100 && budget.alert_80_sent_at.nil?
        Rails.logger.warn "[BUDGET ALERT] User##{budget.user_id} — Categoria##{budget.category_id} " \
                          "atingiu #{pct.round(1)}% do orçamento (#{spent} de #{limit})"
        budget.update!(alert_80_sent_at: Time.current)
      end
    end
  end
end
