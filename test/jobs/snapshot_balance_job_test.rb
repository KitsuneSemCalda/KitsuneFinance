require "test_helper"

class SnapshotBalanceJobTest < ActiveJob::TestCase
  test "creates balance snapshots for all users" do
    assert_difference("BalanceSnapshot.count", User.count) do
      SnapshotBalanceJob.perform_now
    end
  end

  test "snapshot has correct total_balance" do
    SnapshotBalanceJob.perform_now
    snapshot = BalanceSnapshot.last
    assert_not_nil snapshot.total_balance
    assert_not_nil snapshot.net_worth
  end
end