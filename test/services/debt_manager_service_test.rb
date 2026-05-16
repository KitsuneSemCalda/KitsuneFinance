require "test_helper"

class DebtManagerServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "process_monthly_payment decrements remaining installments" do
    debt = debts(:one)
    initial = debt.remaining_installments
    DebtManagerService.process_monthly_payment(debt)
    assert_equal initial - 1, debt.reload.remaining_installments
  end

  test "does not decrement below zero" do
    debt = debts(:one)
    debt.update!(remaining_installments: 0)
    DebtManagerService.process_monthly_payment(debt)
    assert_equal 0, debt.reload.remaining_installments
  end
end