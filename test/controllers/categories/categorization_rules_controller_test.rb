require "test_helper"

class Categories::CategorizationRulesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @category = categories(:one)
    sign_in @user
  end

  test "should get index" do
    get dashboard_category_categorization_rules_path(@category)
    assert_response :success
  end

  test "index lists all rules for current user" do
    get dashboard_category_categorization_rules_path(@category)
    assert_response :success
    assert_select "h2", text: "Regras de Categorização"
  end

  test "should create categorization rule" do
    assert_difference("CategorizationRule.count") do
      post dashboard_category_categorization_rules_path(@category),
           params: { categorization_rule: { keyword: "TESTE" } }
    end
    assert_redirected_to edit_dashboard_category_path(@category)
  end

  test "should not create rule without keyword" do
    assert_no_difference("CategorizationRule.count") do
      post dashboard_category_categorization_rules_path(@category),
           params: { categorization_rule: { keyword: "" } }
    end
    assert_redirected_to edit_dashboard_category_path(@category)
  end

  test "should destroy categorization rule" do
    rule = categorization_rules(:one)
    assert_difference("CategorizationRule.count", -1) do
      delete dashboard_category_categorization_rule_path(@category, rule)
    end
    assert_redirected_to edit_dashboard_category_path(@category)
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_category_categorization_rules_path(@category)
    assert_redirected_to new_user_session_path
  end

  test "cannot access another user category" do
    other_category = categories(:two)
    post dashboard_category_categorization_rules_path(other_category),
         params: { categorization_rule: { keyword: "TESTE" } }
    assert_response :not_found
  end
end
