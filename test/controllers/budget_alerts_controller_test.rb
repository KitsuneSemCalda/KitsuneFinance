require "test_helper"

class BudgetAlertsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @budget = budgets(:one)
    sign_in @user
  end

  test "index shows empty state when budgets are under 80%" do
    get dashboard_budget_alerts_url
    assert_select "p", text: /Nenhum alerta/
  end

  test "index includes budgets at or above 80%" do
    Transaction.create!(user: @user, account: accounts(:one), category: @budget.category,
                        description: "Gasto", amount: 81000, transaction_type: "expense",
                        date: Date.new(2026, 5, 10))
    get dashboard_budget_alerts_url
    assert_select "h3", text: /Alimentação/
  end

  test "index does not show budgets under 80% when others are over" do
    other_cat = Category.create!(user: @user, name: "Saúde", transaction_type: "expense")
    Budget.create!(user: @user, category: other_cat, month: 5, year: 2026, limit_amount: 50000)
    Transaction.create!(user: @user, account: accounts(:one), category: @budget.category,
                        description: "Gasto", amount: 90000, transaction_type: "expense",
                        date: Date.new(2026, 5, 10))
    get dashboard_budget_alerts_url
    assert_select "h3", text: /Alimentação/
    assert_select "h3", text: /Saúde/, count: 0
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_budget_alerts_url
    assert_redirected_to new_user_session_path
  end
end