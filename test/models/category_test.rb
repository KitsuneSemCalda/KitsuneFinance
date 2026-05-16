require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "should be valid with valid attributes" do
    category = Category.new(user: @user, name: "Transporte", transaction_type: "expense")
    assert category.valid?
  end

  test "should not be valid without name" do
    category = Category.new(user: @user, name: nil, transaction_type: "expense")
    assert_not category.valid?
  end

  test "should not be valid without transaction_type" do
    category = Category.new(user: @user, name: "Test", transaction_type: nil)
    assert_not category.valid?
  end

  test "should enforce unique name per user" do
    existing = categories(:one)
    category = Category.new(user: @user, name: existing.name, transaction_type: "expense")
    assert_not category.valid?
  end

  test "should allow same name for different users" do
    existing = categories(:one)
    category = Category.new(user: users(:two), name: existing.name, transaction_type: "expense")
    assert category.valid?
  end

  test "income scope" do
    Category.create(user: @user, name: "Freela", transaction_type: "income")
    assert_includes Category.income.pluck(:name), "Freela"
  end

  test "expense scope" do
    assert_includes Category.expense.pluck(:name), "Alimentação"
  end
end