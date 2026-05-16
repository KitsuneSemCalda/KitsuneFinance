require "test_helper"

class BalanceSnapshotTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "should be valid with valid attributes" do
    snapshot = BalanceSnapshot.new(
      user: @user,
      snapshot_date: Date.new(2026, 6, 1),
      total_balance: 100000,
      total_investments: 50000,
      net_worth: 150000
    )
    assert snapshot.valid?
  end

  test "should not be valid without snapshot_date" do
    snapshot = BalanceSnapshot.new(
      user: @user,
      snapshot_date: nil,
      total_balance: 100000,
      total_investments: 50000,
      net_worth: 150000
    )
    assert_not snapshot.valid?
  end

  test "should not be valid without total_balance" do
    snapshot = BalanceSnapshot.new(
      user: @user,
      snapshot_date: Date.new(2026, 6, 1),
      total_balance: nil,
      total_investments: 50000,
      net_worth: 150000
    )
    assert_not snapshot.valid?
  end

  test "should enforce unique snapshot_date per user" do
    existing = balance_snapshots(:one)
    snapshot = BalanceSnapshot.new(
      user: @user,
      snapshot_date: existing.snapshot_date,
      total_balance: 200000,
      total_investments: 30000,
      net_worth: 230000
    )
    assert_not snapshot.valid?
  end

  test "should allow same date for different users" do
    existing = balance_snapshots(:one)
    snapshot = BalanceSnapshot.new(
      user: users(:two),
      snapshot_date: existing.snapshot_date,
      total_balance: 999999,
      total_investments: 1,
      net_worth: 1000000
    )
    assert snapshot.valid?
  end

  test "stores monetary values as integer cents" do
    snapshot = BalanceSnapshot.create!(
      user: @user,
      snapshot_date: Date.new(2026, 6, 1),
      total_balance: 100050,
      total_investments: 50025,
      net_worth: 150075
    )
    assert_equal 100050, snapshot.total_balance
    assert_equal 50025, snapshot.total_investments
    assert_equal 150075, snapshot.net_worth
    assert_kind_of Integer, snapshot.total_balance
  end

  test "belongs to user and is destroyed with user" do
    assert_difference("BalanceSnapshot.count", -1) do
      @user.destroy
    end
  end
end
