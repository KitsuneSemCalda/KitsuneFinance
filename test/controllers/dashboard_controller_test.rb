require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get dashboard_url
    assert_response :success
  end

  test "should get reports" do
    get dashboard_reports_url
    assert_response :success
  end

  test "should get simulation" do
    get dashboard_simulation_url
    assert_response :success
  end

  test "simulation accepts params" do
    get dashboard_simulation_url, params: { salary_adj: 10, expense_adj: 5 }
    assert_response :success
    assert_select "p", /Salário Projetado/
  end

  test "should get health" do
    get dashboard_health_url
    assert_response :success
  end

  test "should get settings" do
    get dashboard_settings_url
    assert_response :success
  end

  test "should update settings" do
    patch dashboard_settings_url, params: { user: { monthly_salary: 5000 } }
    assert_redirected_to dashboard_settings_path
    @user.reload
    assert_equal 500000, @user.monthly_salary
  end

  test "should require authentication" do
    sign_out @user
    get dashboard_url
    assert_redirected_to new_user_session_path
  end
end
