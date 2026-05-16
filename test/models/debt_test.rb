require "test_helper"

class DebtTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "should be valid with valid attributes" do
    debt = Debt.new(user: @user, name: "Empréstimo", total_amount: 1000000, monthly_payment: 50000, installments_count: 24, remaining_installments: 24)
    assert debt.valid?
  end

  test "should not be valid without name" do
    debt = Debt.new(user: @user, name: nil, total_amount: 1000000, monthly_payment: 50000, installments_count: 24, remaining_installments: 24)
    assert_not debt.valid?
  end

  test "progress_pct when all paid" do
    debt = Debt.new(installments_count: 24, remaining_installments: 0)
    assert_equal 100.0, debt.progress_pct
  end

  test "progress_pct half paid" do
    debt = Debt.new(installments_count: 24, remaining_installments: 12)
    assert_equal 50.0, debt.progress_pct
  end

  test "total_remaining" do
    debt = Debt.new(monthly_payment: 50000, remaining_installments: 12)
    assert_equal 600000, debt.total_remaining
  end
end