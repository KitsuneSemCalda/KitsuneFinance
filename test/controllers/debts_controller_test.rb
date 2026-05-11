require "test_helper"

class DebtsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @debt = debts(:one)
    sign_in @user
  end

  test "should get index" do
    get dashboard_debts_url
    assert_response :success
  end

  test "should get new" do
    get new_dashboard_debt_url
    assert_response :success
  end

  test "should create debt" do
    assert_difference("Debt.count") do
      post dashboard_debts_url, params: { debt: { name: "New Debt", total_amount: 10000, monthly_payment: 500, installments_count: 12, remaining_installments: 12 } }
    end
    assert_redirected_to dashboard_debts_path
  end

  test "should get edit" do
    get edit_dashboard_debt_url(@debt)
    assert_response :success
  end

  test "should update debt" do
    patch dashboard_debt_url(@debt), params: { debt: { name: "Updated Debt" } }
    assert_redirected_to dashboard_debts_path
    @debt.reload
    assert_equal "Updated Debt", @debt.name
  end

  test "should destroy debt" do
    assert_difference("Debt.count", -1) do
      delete dashboard_debt_url(@debt)
    end
    assert_redirected_to dashboard_debts_path
  end
end
