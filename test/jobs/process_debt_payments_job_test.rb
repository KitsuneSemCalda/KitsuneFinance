require "test_helper"

class ProcessDebtPaymentsJobTest < ActiveJob::TestCase
  test "decrements remaining installments for all debts" do
    debt = debts(:one)
    initial = debt.remaining_installments
    ProcessDebtPaymentsJob.perform_now
    assert_equal initial - 1, debt.reload.remaining_installments
  end

  test "does not decrement debt with zero remaining installments" do
    debt = debts(:one)
    debt.update!(remaining_installments: 0)
    ProcessDebtPaymentsJob.perform_now
    assert_equal 0, debt.reload.remaining_installments
  end

  test "decrements all debts for all users" do
    debt1 = debts(:one)
    debt2 = debts(:two)
    initial1 = debt1.remaining_installments
    initial2 = debt2.remaining_installments
    ProcessDebtPaymentsJob.perform_now
    assert_equal initial1 - 1, debt1.reload.remaining_installments
    assert_equal initial2 - 1, debt2.reload.remaining_installments
  end
end
