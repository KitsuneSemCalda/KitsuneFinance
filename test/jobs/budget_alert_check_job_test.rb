require "test_helper"

class BudgetAlertCheckJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @budget = budgets(:one)
    @category = categories(:one)
  end

  test "creates notification when budget exceeds 80%" do
    Transaction.create!(
      user: @user, account: accounts(:one),
      category: @budget.category, description: "Gastos",
      amount: 85000, transaction_type: "expense", date: Date.new(2026, 5, 10)
    )
    assert_difference("Notification.count") do
      BudgetAlertCheckJob.perform_now
    end
  end

  test "does not create notification when budget is under 80%" do
    assert_no_difference("Notification.count") do
      BudgetAlertCheckJob.perform_now
    end
  end

  test "creates 100% alert when budget is exceeded" do
    Transaction.create!(
      user: @user, account: accounts(:one),
      category: @budget.category, description: "Gastos",
      amount: 110000, transaction_type: "expense", date: Date.new(2026, 5, 10)
    )
    assert_difference("Notification.count") do
      BudgetAlertCheckJob.perform_now
    end
    assert_not_nil @budget.reload.alert_100_sent_at
  end

  test "does not send duplicate 80% alert" do
    @budget.update!(alert_80_sent_at: Time.current)
    Transaction.create!(
      user: @user, account: accounts(:one),
      category: @budget.category, description: "Gastos",
      amount: 60000, transaction_type: "expense", date: Date.new(2026, 5, 10)
    )
    assert_no_difference("Notification.count") do
      BudgetAlertCheckJob.perform_now
    end
  end
end
