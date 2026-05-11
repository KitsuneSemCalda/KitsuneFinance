require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @category = categories(:one)
    @budget = budgets(:one)
    sign_in @user
  end

  test "should get index" do
    get dashboard_budgets_url
    assert_response :success
  end

  test "should get index with month and year params" do
    get dashboard_budgets_url, params: { month: 5, year: 2026 }
    assert_response :success
  end

  test "should get new" do
    get new_dashboard_budget_url
    assert_response :success
  end

  test "should create budget" do
    assert_difference("Budget.count") do
      post dashboard_budgets_url, params: { budget: { category_id: @category.id, month: 6, year: 2026, limit_amount: 50000 } }
    end
    assert_redirected_to dashboard_budgets_path(month: 6, year: 2026)
  end

  test "should get edit" do
    get edit_dashboard_budget_url(@budget)
    assert_response :success
  end

  test "should update budget" do
    patch dashboard_budget_url(@budget), params: { budget: { limit_amount: 75000 } }
    assert_redirected_to dashboard_budgets_path(month: @budget.month, year: @budget.year)
    @budget.reload
    assert_equal 75000, @budget.limit_amount
  end

  test "should destroy budget" do
    assert_difference("Budget.count", -1) do
      delete dashboard_budget_url(@budget)
    end
    assert_redirected_to dashboard_budgets_path(month: @budget.month, year: @budget.year)
  end
end
