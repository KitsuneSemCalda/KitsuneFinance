require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @category = categories(:one)
    sign_in @user
  end

  test "index lists user categories" do
    get dashboard_categories_url
    assert_select "span", text: /Alimentação/
    assert_no_match /Salário/, response.body
  end

  test "index returns JSON with category attributes" do
    get dashboard_categories_url(format: :json)
    assert_equal "application/json", response.media_type
    data = response.parsed_body
    assert_kind_of Array, data
    category = data.find { |c| c["name"] == "Alimentação" }
    assert category
    assert_equal "expense", category["transaction_type"]
  end

  test "new renders form fields" do
    get new_dashboard_category_url
    assert_select "input[name='category[name]']"
    assert_select "input[type='radio'][name='category[transaction_type]']"
  end

  test "create with defaults" do
    assert_difference("Category.count") do
      post dashboard_categories_url, params: { category: { name: "Transporte", transaction_type: "expense" } }
    end
    created = Category.last
    assert_equal "Transporte", created.name
    assert_equal "expense", created.transaction_type
    assert_equal "zinc", created.color
    assert_equal false, created.system_default
    assert_equal @user, created.user
    assert_redirected_to dashboard_categories_path
  end

  test "create fails with duplicate name" do
    assert_no_difference("Category.count") do
      post dashboard_categories_url, params: { category: { name: @category.name, transaction_type: "expense" } }
    end
    assert_response :unprocessable_entity
  end

  test "edit form is pre-filled" do
    get edit_dashboard_category_url(@category)
    assert_select "input[name='category[name]'][value='Alimentação']"
  end

  test "update changes attributes" do
    patch dashboard_category_url(@category), params: { category: { name: "Alimentação e Mercado", color: "amber" } }
    @category.reload
    assert_equal "Alimentação e Mercado", @category.name
    assert_equal "amber", @category.color
    assert_redirected_to dashboard_categories_path
  end

  test "destroy removes category and cascades" do
    assert_difference("Category.count", -1) { delete dashboard_category_url(@category) }
    assert_redirected_to dashboard_categories_path
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_categories_url
    assert_redirected_to new_user_session_path
  end
end