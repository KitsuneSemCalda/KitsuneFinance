require "test_helper"

class AutoRenewBudgetsJobTest < ActiveJob::TestCase
  test "creates next month budget from current" do
    travel_to Date.new(2026, 6, 1) do
      assert_difference("Budget.count") do
        AutoRenewBudgetsJob.perform_now
      end
    end
  end

  test "does not duplicate if next month already exists" do
    user = users(:one)
    Budget.create!(user: user, category: categories(:one), month: 6, year: 2026, limit_amount: 50000)
    travel_to Date.new(2026, 6, 1) do
      assert_no_difference("Budget.count") do
        AutoRenewBudgetsJob.perform_now
      end
    end
  end
end