require "test_helper"

class GoalStatusCheckJobTest < ActiveJob::TestCase
  setup do
    @goal = goals(:one)
    @goal.update!(deadline: Date.yesterday)
  end

  test "pauses goals past deadline" do
    GoalStatusCheckJob.perform_now
    assert_equal "paused", @goal.reload.status
  end

  test "does not pause active goals within deadline" do
    @goal.update!(deadline: Date.today + 30)
    GoalStatusCheckJob.perform_now
    assert_equal "active", @goal.reload.status
  end
end