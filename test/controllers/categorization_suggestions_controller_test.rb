require "test_helper"

class CategorizationSuggestionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @suggestion = categorization_suggestions(:one)
    sign_in @user
  end

  test "index lists user suggestions" do
    get dashboard_categorization_suggestions_url
    assert_select "td", text: /UBER/
    assert_no_match /IFOOD/, response.body
  end

  test "new renders form fields" do
    get new_dashboard_categorization_suggestion_url
    assert_select "input[name='categorization_suggestion[keyword]']"
    assert_select "select[name='categorization_suggestion[category_id]']"
  end

  test "create with keyword and category" do
    category = categories(:one)
    assert_difference("CategorizationSuggestion.count") do
      post dashboard_categorization_suggestions_url, params: {
        categorization_suggestion: { keyword: "PADARIA", category_id: category.id }
      }
    end
    created = CategorizationSuggestion.last
    assert_equal "PADARIA", created.keyword
    assert_equal category, created.category
    assert_equal @user, created.user
    assert_redirected_to dashboard_categorization_suggestions_path
  end

  test "create fails without keyword" do
    assert_no_difference("CategorizationSuggestion.count") do
      post dashboard_categorization_suggestions_url, params: {
        categorization_suggestion: { keyword: "", category_id: categories(:one).id }
      }
    end
    assert_response :unprocessable_entity
  end

  test "destroy removes suggestion" do
    assert_difference("CategorizationSuggestion.count", -1) do
      delete dashboard_categorization_suggestion_url(@suggestion)
    end
    assert_redirected_to dashboard_categorization_suggestions_path
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_categorization_suggestions_url
    assert_redirected_to new_user_session_path
  end
end