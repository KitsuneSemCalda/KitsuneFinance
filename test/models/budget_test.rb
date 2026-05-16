require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @category = categories(:one)
  end

  test "should be valid with valid attributes" do
    budget = Budget.new(user: @user, category: @category, month: 6, year: 2026, limit_amount: 50000)
    assert budget.valid?
  end

  test "should not be valid without limit_amount" do
    budget = Budget.new(user: @user, category: @category, month: 6, year: 2026, limit_amount: nil)
    assert_not budget.valid?
  end

  test "should calculate spent_amount correctly" do
    budget = budgets(:one)
    # fixture already has a May 2026 expense for this category (25000)
    assert_equal 25000, budget.spent_amount
  end

  test "should calculate progress_pct correctly" do
    budget = budgets(:one)
    # fixture has 25000 expense, limit is 100000 → 25%
    assert_equal 25.0, budget.progress_pct
  end

  test "should return 0 progress_pct when no transactions" do
    other_category = Category.create!(user: @user, name: "Lazer", transaction_type: "expense")
    budget = Budget.create!(user: @user, category: other_category, month: 6, year: 2026, limit_amount: 50000)
    assert_equal 0, budget.progress_pct
  end

  test "remaining_amount" do
    budget = budgets(:one)
    # 100000 limit - 25000 from fixture = 75000
    assert_equal 75000, budget.remaining_amount
  end

  test "over_budget?" do
    budget = budgets(:one)
    Transaction.create!(user: @user, account: accounts(:one), category: @category, description: "Extra", amount: 100000, transaction_type: "expense", date: Date.new(2026, 5, 10))
    assert budget.over_budget?
  end
end