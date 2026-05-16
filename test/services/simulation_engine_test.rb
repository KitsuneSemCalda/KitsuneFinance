require "test_helper"

class SimulationEngineTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @engine = SimulationEngine.new(@user)
  end

  test "forecast returns hash with all keys" do
    result = @engine.forecast({})
    assert_kind_of Hash, result
    assert_includes result.keys, :projected_salary
    assert_includes result.keys, :projected_expenses
    assert_includes result.keys, :monthly_savings
    assert_includes result.keys, :balance
    assert_includes result.keys, :debt_payoff_months
    assert_includes result.keys, :projected_net_worth_12m
    assert_includes result.keys, :goal_projections
  end

  test "forecast applies salary adjustment" do
    @user.update!(monthly_salary: 500000)
    base = @engine.forecast({})
    adjusted = @engine.forecast({ salary_adjustment: 0.1 })
    assert adjusted[:projected_salary] > base[:projected_salary]
  end

  test "forecast applies expense reduction" do
    @user.update!(monthly_salary: 500000)
    base = @engine.forecast({})
    adjusted = @engine.forecast({ expense_adjustment: 0.2 })
    assert adjusted[:projected_expenses] < base[:projected_expenses]
  end

  test "goal_projections includes active goals" do
    result = @engine.forecast({})
    assert_kind_of Array, result[:goal_projections]
  end

  test "goal_projections excludes completed goals" do
    goals(:one).update!(status: "completed")
    result = @engine.forecast({})
    goal_names = result[:goal_projections].map { |g| g[:name] }
    assert_not_includes goal_names, "Viagem"
  end

  test "forecast with zero monthly_debts returns nil payoff months" do
    users(:one).debts.destroy_all
    result = @engine.forecast({})
    assert_nil result[:debt_payoff_months]
    assert_equal 0, result[:total_debt_remaining]
  end

  test "forecast when expenses exceed salary" do
    @user.update!(monthly_salary: 100000)
    result = @engine.forecast({})
    assert_equal 0, result[:monthly_savings]
    assert_equal 0, result[:projected_net_worth_12m]
  end

  test "forecast with no active goals returns empty projections" do
    Goal.where(user: @user).update_all(status: "completed")
    result = @engine.forecast({})
    assert_equal [], result[:goal_projections]
  end
end