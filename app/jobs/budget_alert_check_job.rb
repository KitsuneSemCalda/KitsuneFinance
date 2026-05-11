class BudgetAlertCheckJob < ApplicationJob
  queue_as :default

  def perform
    Budget.find_each do |budget|
      spent = budget.spent_amount
      limit = budget.limit_amount
      next if limit.zero?

      pct = (spent.to_f / limit) * 100
      category_name = budget.category.name

      if pct >= 100 && budget.alert_100_sent_at.nil?
        NotificationService.notify(
          budget.user,
          "Orçamento estourado!",
          "A categoria #{category_name} excedeu 100% do orçamento (R$ #{'%.2f' % (spent / 100.0)} de R$ #{'%.2f' % (limit / 100.0)})",
          type: :danger,
          link: "/budgets"
        )
        budget.update!(alert_100_sent_at: Time.current)
      end

      if pct >= 80 && pct < 100 && budget.alert_80_sent_at.nil?
        NotificationService.notify(
          budget.user,
          "Orçamento quase no limite",
          "A categoria #{category_name} atingiu #{pct.round(1)}% do orçamento (R$ #{'%.2f' % (spent / 100.0)} de R$ #{'%.2f' % (limit / 100.0)})",
          type: :warning,
          link: "/budgets"
        )
        budget.update!(alert_80_sent_at: Time.current)
      end
    end
  end
end
