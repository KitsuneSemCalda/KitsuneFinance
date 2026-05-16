require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @category = categories(:one)
    @budget = budgets(:one)
    sign_in @user
  end

  test "index shows current month budgets" do
    get dashboard_budgets_url
    assert_select "h2", text: "Orçamento"
  end

  test "index filters by month and year" do
    Budget.create!(user: @user, category: @category, month: 6, year: 2026, limit_amount: 50000)
    get dashboard_budgets_url, params: { month: 6, year: 2026 }
    assert_response :success
  end

  test "new renders form fields" do
    get new_dashboard_budget_url
    assert_select "select[name='budget[category_id]']"
    assert_select "input[name='budget[limit_amount]']"
  end

  test "create persists with all fields" do
    assert_difference("Budget.count") do
      post dashboard_budgets_url, params: {
        budget: { category_id: @category.id, month: 6, year: 2026, limit_amount: 50000 }
      }
    end
    created = Budget.last
    assert_equal 50000, created.limit_amount
    assert_equal 6, created.month
    assert_equal 2026, created.year
    assert_equal @category, created.category
    assert_redirected_to dashboard_budgets_path(month: 6, year: 2026)
  end

  test "create fails with invalid month" do
    assert_no_difference("Budget.count") do
      post dashboard_budgets_url, params: {
        budget: { category_id: @category.id, month: 13, year: 2026, limit_amount: 50000 }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edit form is pre-filled" do
    get edit_dashboard_budget_url(@budget)
    assert_select "input[name='budget[limit_amount]']"
  end

  test "update changes limit_value" do
    patch dashboard_budget_url(@budget), params: { budget: { limit_amount: 75000 } }
    @budget.reload
    assert_equal 75000, @budget.limit_amount
    assert_redirected_to dashboard_budgets_path(month: @budget.month, year: @budget.year)
  end

  test "destroy removes budget" do
    assert_difference("Budget.count", -1) { delete dashboard_budget_url(@budget) }
    assert_redirected_to dashboard_budgets_path(month: @budget.month, year: @budget.year)
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_budgets_url
    assert_redirected_to new_user_session_path
  end
end