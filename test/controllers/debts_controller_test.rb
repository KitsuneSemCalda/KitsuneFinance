require "test_helper"

class DebtsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @debt = debts(:one)
    sign_in @user
  end

  test "index lists user debts with progress" do
    get dashboard_debts_url
    assert_select "h2", text: /Dívidas/
  end

  test "new renders form fields" do
    get new_dashboard_debt_url
    assert_select "input[name='debt[name]']"
    assert_select "input[name='debt[total_amount]']"
    assert_select "input[name='debt[monthly_payment]']"
  end

  test "create persists with all fields" do
    assert_difference("Debt.count") do
      post dashboard_debts_url, params: {
        debt: { name: "Empréstimo", total_amount: 10000, monthly_payment: 500,
                installments_count: 24, remaining_installments: 24 }
      }
    end
    created = Debt.last
    assert_equal "Empréstimo", created.name
    assert_equal 1000000, created.total_amount
    assert_equal 50000, created.monthly_payment
    assert_equal 24, created.installments_count
    assert_equal @user, created.user
    assert_redirected_to dashboard_debts_path
  end

  test "create fails without name" do
    assert_no_difference("Debt.count") do
      post dashboard_debts_url, params: {
        debt: { name: "", total_amount: 1000, monthly_payment: 100,
                installments_count: 12, remaining_installments: 12 }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edit form is pre-filled" do
    get edit_dashboard_debt_url(@debt)
    assert_select "input[name='debt[name]'][value=?]", @debt.name
  end

  test "update changes attributes" do
    patch dashboard_debt_url(@debt), params: { debt: { name: "Carro Novo" } }
    @debt.reload
    assert_equal "Carro Novo", @debt.name
    assert_redirected_to dashboard_debts_path
  end

  test "destroy removes debt" do
    assert_difference("Debt.count", -1) { delete dashboard_debt_url(@debt) }
    assert_redirected_to dashboard_debts_path
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_debts_url
    assert_redirected_to new_user_session_path
  end
end