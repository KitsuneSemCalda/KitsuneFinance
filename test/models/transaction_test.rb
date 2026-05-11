require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @account = accounts(:one)
    @goal = goals(:one)
  end

  test "creating transaction linked to goal updates goal progress" do
    initial_amount = @goal.current_amount
    amount = 100
    
    assert_difference -> { @goal.reload.current_amount }, amount do
      @user.transactions.create!(
        account: @account,
        goal: @goal,
        amount: amount,
        transaction_type: "expense",
        description: "Test",
        date: Date.today
      )
    end
  end

  test "destroying transaction linked to goal reverts goal progress" do
    amount = 100
    transaction = @user.transactions.create!(
      account: @account,
      goal: @goal,
      amount: amount,
      transaction_type: "expense",
      description: "Test",
      date: Date.today
    )
    
    assert_difference -> { @goal.reload.current_amount }, -amount do
      transaction.destroy
    end
  end

  test "updating transaction linked to goal updates goal progress" do
    amount = 100
    transaction = @user.transactions.create!(
      account: @account,
      goal: @goal,
      amount: amount,
      transaction_type: "expense",
      description: "Test",
      date: Date.today
    )
    
    new_amount = 250
    diff = new_amount - amount
    
    assert_difference -> { @goal.reload.current_amount }, diff do
      transaction.update!(amount: new_amount)
    end
  end
end
