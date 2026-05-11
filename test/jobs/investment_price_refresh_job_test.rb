require "test_helper"

class InvestmentPriceRefreshJobTest < ActiveJob::TestCase
  test "updates price for specific investment" do
    inv = investments(:one)
    old_price = inv.current_price

    stub_method(PriceService, :fetch_price, 50.0) do
      InvestmentPriceRefreshJob.perform_now(inv.id)
    end

    assert_equal 5000, inv.reload.current_price
  end

  test "does nothing when investment not found" do
    assert_nothing_raised do
      InvestmentPriceRefreshJob.perform_now(99999)
    end
  end

  test "does nothing when fetch_price returns nil" do
    inv = investments(:one)
    old_price = inv.current_price

    stub_method(PriceService, :fetch_price, nil) do
      InvestmentPriceRefreshJob.perform_now(inv.id)
    end

    assert_equal old_price, inv.reload.current_price
  end
end
