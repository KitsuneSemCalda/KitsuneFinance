require "test_helper"

class CategorizationRuleTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @category = categories(:one)
  end

  test "should be valid with valid attributes" do
    rule = CategorizationRule.new(user: @user, category: @category, keyword: "FARMACIA")
    assert rule.valid?
  end

  test ".match returns category when keyword matches" do
    rule = categorization_rules(:one)
    category = CategorizationRule.match("COMPRA NO MERCADO", @user)
    assert_equal rule.category, category
  end

  test ".match returns nil when no keyword matches" do
    category = CategorizationRule.match("ALGO ALEATORIO", @user)
    assert_nil category
  end

  test ".match is case insensitive" do
    rule = categorization_rules(:one)
    category = CategorizationRule.match("compra no mercado", @user)
    assert_equal rule.category, category
  end

  test "should reject keyword with LIKE wildcard %" do
    rule = CategorizationRule.new(user: @user, category: @category, keyword: "COM%")
    assert_not rule.valid?
  end

  test "should reject keyword with LIKE wildcard _" do
    rule = CategorizationRule.new(user: @user, category: @category, keyword: "COM_")
    assert_not rule.valid?
  end
end