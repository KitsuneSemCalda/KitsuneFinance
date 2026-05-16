require "test_helper"

class GoalsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @goal = goals(:one)
    @account = accounts(:one)
    sign_in @user
  end

  test "index lists user goals with progress" do
    get dashboard_goals_url
    assert_select "h2", text: /Metas/
  end

  test "new renders form fields" do
    get new_dashboard_goal_url
    assert_select "input[name='goal[name]']"
    assert_select "input[name='goal[target_amount]']"
  end

  test "create persists with controller converting reais to cents" do
    assert_difference("Goal.count") do
      post dashboard_goals_url, params: {
        goal: { name: "Nova Meta", target_amount: 2000, current_amount: 0,
                status: "active", color: "indigo" }
      }
    end
    created = Goal.last
    assert_equal "Nova Meta", created.name
    assert_equal 200000, created.target_amount  # 2000 * 100
    assert_equal 0, created.current_amount
    assert_equal "active", created.status
    assert_equal @user, created.user
    assert_redirected_to dashboard_goals_path
  end

  test "create fails without name" do
    assert_no_difference("Goal.count") do
      post dashboard_goals_url, params: {
        goal: { name: "", target_amount: 1000, current_amount: 0, status: "active", color: "indigo" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edit form is pre-filled with name" do
    get edit_dashboard_goal_url(@goal)
    assert_select "input[name='goal[name]'][value=?]", @goal.name
  end

  test "update changes attributes" do
    patch dashboard_goal_url(@goal), params: { goal: { name: "Meta Atualizada", color: "emerald" } }
    @goal.reload
    assert_equal "Meta Atualizada", @goal.name
    assert_equal "emerald", @goal.color
    assert_redirected_to dashboard_goals_path
  end

  test "destroy removes goal" do
    assert_difference("Goal.count", -1) { delete dashboard_goal_url(@goal) }
    assert_redirected_to dashboard_goals_path
  end

  test "contribute creates transaction and increases current_amount" do
    amount = 500
    assert_difference("Transaction.count") do
      patch contribute_dashboard_goal_url(@goal), params: { amount: amount, account_id: @account.id }
    end
    @goal.reload
    assert_equal amount, @goal.current_amount
    t = Transaction.last
    assert_equal @goal, t.goal
    assert_equal amount, t.amount
    assert_redirected_to dashboard_goals_path
  end

  test "contribute without account creates transaction without account_id" do
    assert_difference("Transaction.count") do
      patch contribute_dashboard_goal_url(@goal), params: { amount: 500 }
    end
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_goals_url
    assert_redirected_to new_user_session_path
  end
end