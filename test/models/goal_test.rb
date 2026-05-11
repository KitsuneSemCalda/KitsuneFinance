require "test_helper"

class GoalTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @goal = Goal.new(
      user: @user,
      name: "Viagem",
      target_amount: 5000,
      current_amount: 0,
      status: "active",
      color: "indigo"
    )
  end

  test "should be valid" do
    assert @goal.valid?
  end

  test "name should be present" do
    @goal.name = ""
    assert_not @goal.valid?
  end

  test "target_amount should be greater than 0" do
    @goal.target_amount = 0
    assert_not @goal.valid?
    @goal.target_amount = -1
    assert_not @goal.valid?
  end

  test "current_amount should be non-negative" do
    @goal.current_amount = -1
    assert_not @goal.valid?
  end

  test "progress_pct calculation" do
    @goal.current_amount = 2500
    @goal.target_amount = 5000
    assert_equal 50.0, @goal.progress_pct

    @goal.current_amount = 6000
    assert_equal 100.0, @goal.progress_pct
  end

  test "should auto-complete status when target reached" do
    @goal.save
    assert_equal "active", @goal.status
    
    @goal.current_amount = 5000
    @goal.save
    assert_equal "completed", @goal.status
  end
end
