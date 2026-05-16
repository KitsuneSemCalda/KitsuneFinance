require "test_helper"

class AccountTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "should be valid with valid attributes" do
    account = Account.new(user: @user, name: "Nova Conta", account_type: "checking", balance: 0, currency: "BRL")
    assert account.valid?
  end

  test "should not be valid without name" do
    account = Account.new(user: @user, name: nil, account_type: "checking", balance: 0, currency: "BRL")
    assert_not account.valid?
  end

  test "should not be valid without account_type" do
    account = Account.new(user: @user, name: "Test", account_type: nil, balance: 0, currency: "BRL")
    assert_not account.valid?
  end

  test "should not be valid with invalid account_type" do
    account = Account.new(user: @user, name: "Test", account_type: "invalid", balance: 0, currency: "BRL")
    assert_not account.valid?
  end

  test "should enforce unique name per user" do
    existing = accounts(:one)
    account = Account.new(user: @user, name: existing.name, account_type: "checking", balance: 0, currency: "BRL")
    assert_not account.valid?
  end

  test "should allow same name for different users" do
    existing = accounts(:one)
    account = Account.new(user: users(:two), name: existing.name, account_type: "checking", balance: 0, currency: "BRL")
    assert account.valid?
  end
end