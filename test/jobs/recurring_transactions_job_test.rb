require "test_helper"

class RecurringTransactionsJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @template = Transaction.create!(
      user: @user, account: @account,
      description: "Aluguel Recorrente", amount: 200000,
      transaction_type: "expense", date: Date.today - 1.month,
      recurrent: true, recurrence_period: "monthly"
    )
  end

  test "creates new transaction for recurring template" do
    assert_difference("Transaction.count") do
      RecurringTransactionsJob.perform_now
    end
  end

  test "does not create duplicate" do
    Transaction.create!(
      user: @user, account: @account,
      description: "Aluguel Recorrente", amount: 200000,
      transaction_type: "expense", date: Date.today,
      recurrent: true, recurrence_period: "monthly"
    )
    assert_no_difference("Transaction.count") do
      RecurringTransactionsJob.perform_now
    end
  end

  test "skips templates with unknown period" do
    @template.update!(recurrence_period: "unknown")
    assert_no_difference("Transaction.count") do
      RecurringTransactionsJob.perform_now
    end
  end
end