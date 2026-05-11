require "test_helper"

class GoalsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @goal = goals(:one)
    @account = accounts(:one)
    sign_in @user
  end

  test "should get index" do
    get dashboard_goals_url
    assert_response :success
  end

  test "should create goal" do
    assert_difference("Goal.count") do
      post dashboard_goals_url, params: { goal: { name: "New Goal", target_amount: 1000, current_amount: 0, status: "active", color: "indigo" } }
    end
    assert_redirected_to dashboard_goals_path
  end

  test "should get edit" do
    get edit_dashboard_goal_url(@goal)
    assert_response :success
  end

  test "should update goal" do
    patch dashboard_goal_url(@goal), params: { goal: { name: "Updated Name" } }
    assert_redirected_to dashboard_goals_path
    @goal.reload
    assert_equal "Updated Name", @goal.name
  end

  test "should destroy goal" do
    assert_difference("Goal.count", -1) do
      delete dashboard_goal_url(@goal)
    end
    assert_redirected_to dashboard_goals_path
  end

  test "should contribute to goal" do
    amount = 500
    assert_difference("Transaction.count", 1) do
      patch contribute_dashboard_goal_url(@goal), params: { amount: amount, account_id: @account.id }
    end
    
    assert_redirected_to dashboard_goals_path
    @goal.reload
    assert_equal amount, @goal.current_amount
    
    transaction = Transaction.last
    assert_equal @goal, transaction.goal
    assert_equal amount, transaction.amount
  end
end
