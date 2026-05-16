require "test_helper"

class CategorizationSuggestionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @category = categories(:one)
  end

  test "should be valid with valid attributes" do
    suggestion = CategorizationSuggestion.new(user: @user, category: @category, keyword: "IFOOD")
    assert suggestion.valid?
  end

  test "should not be valid without keyword" do
    suggestion = CategorizationSuggestion.new(user: @user, category: @category, keyword: nil)
    assert_not suggestion.valid?
  end

  test "should not be valid without category" do
    suggestion = CategorizationSuggestion.new(user: @user, category: nil, keyword: "IFOOD")
    assert_not suggestion.valid?
  end
end