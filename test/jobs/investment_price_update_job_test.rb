require "test_helper"

class InvestmentPriceUpdateJobTest < ActiveJob::TestCase
  test "updates prices for stock_br and fii via fallback" do
    stock = investments(:one)
    fii = investments(:two)

    stub_method(PriceService, :fetch_price, ->(ticker, *, **) {
      case ticker
      when "PETR4" then 30.0
      when "SNLG11" then 1.25
      end
    }) do
      InvestmentPriceUpdateJob.perform_now
    end

    assert_equal 3000, stock.reload.current_price
    assert_equal 125, fii.reload.current_price
  end

  test "updates prices for crypto" do
    crypto = investments(:three)

    stub_method(PriceService, :fetch_price, ->(ticker, *, **) { 500000.0 }) do
      InvestmentPriceUpdateJob.perform_now
    end

    assert_equal 50000000, crypto.reload.current_price
  end

  test "updates prices for international" do
    intl = investments(:four)

    stub_method(PriceService, :fetch_price, ->(ticker, *, **) { 200.0 }) do
      InvestmentPriceUpdateJob.perform_now
    end

    assert_equal 20000, intl.reload.current_price
  end

  test "skips fixed_income and other asset types" do
    user = users(:one)
    fi = Investment.create!(name: "CDB", asset_type: "fixed_income",
                             quantity: 1, avg_price: 100, user: user)
    other = Investment.create!(name: "Outro", asset_type: "other",
                                quantity: 1, avg_price: 100, user: user)

    called = false
    stub_method(PriceService, :fetch_price, ->(*, **) { called = true; nil }) do
      InvestmentPriceUpdateJob.perform_now
    end

    assert called
    assert_equal 0, fi.reload.current_price
    assert_equal 0, other.reload.current_price
  end

  test "runs against all investments with includes(:user)" do
    assert Investment.includes(:user).count >= 4

    stub_method(PriceService, :fetch_price, ->(*, **) { 10.0 }) do
      InvestmentPriceUpdateJob.perform_now
    end

    Investment.find_each do |inv|
      assert_not_equal 0, inv.current_price, "#{inv.name} should have been updated"
    end
  end
end
