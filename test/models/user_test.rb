require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    user = User.new(email: "test@example.com", password: "password123")
    assert user.valid?
  end

  test "should not be valid without email" do
    user = User.new(email: nil, password: "password123")
    assert_not user.valid?
  end

  test "should have associations" do
    user = users(:one)
    assert_respond_to user, :accounts
    assert_respond_to user, :transactions
    assert_respond_to user, :categories
    assert_respond_to user, :budgets
    assert_respond_to user, :goals
    assert_respond_to user, :debts
    assert_respond_to user, :investments
    assert_respond_to user, :notifications
    assert_respond_to user, :trades
    assert_respond_to user, :bill_reminders
    assert_respond_to user, :categorization_rules
    assert_respond_to user, :categorization_suggestions
    assert_respond_to user, :balance_snapshots
  end

  test "associations return records" do
    user = users(:one)
    assert_operator user.accounts.count, :>, 0
    assert_operator user.transactions.count, :>, 0
    assert_operator user.categories.count, :>, 0
    assert_operator user.investments.count, :>, 0
    assert_operator user.goals.count, :>, 0
    assert_operator user.budgets.count, :>, 0
    assert_operator user.debts.count, :>, 0
    assert_operator user.bill_reminders.count, :>, 0
    assert_operator user.categorization_rules.count, :>, 0
    assert_operator user.balance_snapshots.count, :>, 0
  end

  test "annual_salary returns monthly_salary times 12" do
    user = users(:one)
    user.update!(monthly_salary: 500000)
    assert_equal 6000000, user.annual_salary
  end

  test "annual_salary returns 0 when monthly_salary is nil" do
    user = users(:one)
    user.update!(monthly_salary: nil)
    assert_equal 0, user.annual_salary
  end

  test "suggested_monthly_savings returns 10% of salary" do
    user = users(:one)
    user.update!(monthly_salary: 500000)
    assert_equal 50000, user.suggested_monthly_savings
  end

  test "portfolio_metrics returns hash with total, cost, change, change_pct" do
    user = users(:one)
    pm = user.portfolio_metrics
    assert_includes pm, :total_value
    assert_includes pm, :total_cost
    assert_includes pm, :change
    assert_includes pm, :change_pct
  end

  test "financial_health_metrics returns hash with all keys" do
    user = users(:one)
    user.update!(monthly_salary: 500000)
    fm = user.financial_health_metrics
    expected_keys = %i[salary salary_present monthly_income monthly_expense monthly_debts
                       monthly_savings net_worth dti expense_ratio savings_rate
                       net_worth_to_annual health_score]
    expected_keys.each { |k| assert_includes fm, k }
  end

  test "financial_health_metrics handles nil salary" do
    user = users(:one)
    user.update!(monthly_salary: nil)
    fm = user.financial_health_metrics
    assert_equal false, fm[:salary_present]
    assert_nil fm[:dti]
    assert_nil fm[:expense_ratio]
  end

  test "health_color_class returns red for user with no salary and debt" do
    user = users(:one)
    assert_includes %w[red amber emerald], user.health_color_class
  end

  test "health_status_label returns Crítico for user with no salary and debt" do
    user = users(:one)
    assert_includes %w[Crítico Atenção Saudável], user.health_status_label
  end

  test "health_color_class and status_label are consistent" do
    user = users(:one)
    color = user.health_color_class
    label = user.health_status_label
    mapping = { "red" => "Crítico", "amber" => "Atenção", "emerald" => "Saudável" }
    assert_equal mapping[color], label
  end

  test "salary_label returns formatted string when salary present" do
    user = users(:one)
    user.update!(monthly_salary: 500000)
    label = user.salary_label
    assert_match(/R\$/, label)
  end

  test "salary_label returns em dash when salary absent" do
    user = users(:one)
    user.update!(monthly_salary: nil)
    assert_equal "—", user.salary_label
  end

  test "dependent destroy removes associated records" do
    user = users(:one)
    account_count = user.accounts.count
    assert_difference("Account.count", -account_count) { user.destroy }
  end
end
