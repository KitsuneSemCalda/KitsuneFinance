require "application_system_test_case"

class ViewsAccessibilityTest < ApplicationSystemTestCase
  test "home page is accessible" do
    visit root_url
    assert_selector "h1", text: "Sua vida financeira,\nsimplificada e elegante."
    assert_selector ".bg-indigo-600" # Check for modern styling classes
  end

  test "login page is accessible" do
    visit new_user_session_path
    assert_selector "h2", text: "Bem-vindo de volta"
    assert_selector "input[type='email']"
    assert_selector "input[type='password']"
  end

  test "registration page is accessible" do
    visit new_user_registration_path
    assert_selector "h2", text: "Criar Conta"
    assert_selector "input[type='email']"
    assert_selector "input[type='password']"
    assert_selector "input[type='password']", count: 2 # password and confirmation
  end
end
