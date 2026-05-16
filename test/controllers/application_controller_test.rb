require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "redirects to dashboard after sign in" do
    post user_session_path, params: { user: { email: users(:one).email, password: "password" } }
    assert_redirected_to dashboard_path
  end

  test "unauthenticated access redirects to sign in" do
    get dashboard_accounts_url
    assert_redirected_to new_user_session_path
  end
end
