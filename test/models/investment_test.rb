require "test_helper"

class InvestmentTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert investments(:one).valid?
  end

  test "current_value returns quantity * current_price" do
    inv = investments(:one)
    assert_equal inv.quantity * inv.current_price, inv.current_value
  end

  test "total_cost returns quantity * avg_price" do
    inv = investments(:one)
    assert_equal inv.quantity * inv.avg_price, inv.total_cost
  end

  test "gain_loss returns current_value - total_cost" do
    inv = investments(:one)
    expected = (inv.quantity * inv.current_price) - (inv.quantity * inv.avg_price)
    assert_equal expected, inv.gain_loss
  end

  test "gain_loss_pct returns percentage" do
    inv = investments(:one)
    expected = ((inv.current_value.to_f / inv.total_cost) - 1) * 100
    assert_in_delta expected, inv.gain_loss_pct, 0.001
  end

  test "gain_loss_pct returns 0 when total_cost is zero" do
    inv = Investment.new(quantity: 5, avg_price: 0, current_price: 100)
    assert_equal 0, inv.gain_loss_pct
  end

  test "fetch_current_price skips when current_price is present" do
    inv = investments(:one)

    stub_method(PriceService, :fetch_price, 9999) do
      inv.send(:fetch_current_price)
      assert_equal 2800, inv.current_price
    end
  end

  test "fetch_current_price skips when ticker is blank" do
    inv = Investment.new(name: "Test", asset_type: "stock_br", quantity: 1, avg_price: 100, user: users(:one))

    stub_method(PriceService, :fetch_price, 9999) do
      inv.send(:fetch_current_price)
      assert inv.current_price.nil? || inv.current_price == 0
    end
  end

  test "fetch_current_price calls fetch_price for stock_br" do
    inv = Investment.new(name: "Test", ticker: "PETR4", asset_type: "stock_br",
                         quantity: 1, avg_price: 100, user: users(:one))

    called_with = nil
    stub_method(PriceService, :fetch_price, ->(ticker, asset_type, token, **) {
      called_with = [ticker, asset_type, token]; 25.0
    }) do
      inv.send(:fetch_current_price)
      assert_equal ["PETR4", "stock_br", nil], called_with
      assert_equal 2500, inv.current_price
    end
  end

  test "fetch_current_price calls fetch_price for fii" do
    inv = Investment.new(name: "Test", ticker: "HGLG11", asset_type: "fii",
                         quantity: 1, avg_price: 100, user: users(:one))

    called_with = nil
    stub_method(PriceService, :fetch_price, ->(ticker, asset_type, token, **) {
      called_with = [ticker, asset_type, token]; 50.0
    }) do
      inv.send(:fetch_current_price)
      assert_equal ["HGLG11", "fii", nil], called_with
      assert_equal 5000, inv.current_price
    end
  end

  test "fetch_current_price calls fetch_price for crypto" do
    inv = Investment.new(name: "Test", ticker: "BITCOIN", asset_type: "crypto",
                         quantity: 1, avg_price: 100, user: users(:one))

    called_with = nil
    stub_method(PriceService, :fetch_price, ->(ticker, asset_type, token, **) {
      called_with = [ticker, asset_type, token]; 200000.0
    }) do
      inv.send(:fetch_current_price)
      assert_equal ["BITCOIN", "crypto", nil], called_with
      assert_equal 20000000, inv.current_price
    end
  end

  test "fetch_current_price calls fetch_price for international" do
    inv = Investment.new(name: "Test", ticker: "AAPL", asset_type: "international",
                         quantity: 1, avg_price: 100, user: users(:one))

    called_with = nil
    stub_method(PriceService, :fetch_price, ->(ticker, asset_type, token, **) {
      called_with = [ticker, asset_type, token]; 150.0
    }) do
      inv.send(:fetch_current_price)
      assert_equal ["AAPL", "international", nil], called_with
      assert_equal 15000, inv.current_price
    end
  end

  test "fetch_current_price returns nil for fixed_income or other" do
    inv = Investment.new(name: "Test", ticker: "CDB", asset_type: "fixed_income",
                         quantity: 1, avg_price: 100, user: users(:one))
    inv.send(:fetch_current_price)
    assert_equal 0, inv.current_price
  end

  test "before_validation calls fetch_current_price on create" do
    stub_method(PriceService, :fetch_price, 8.50) do
      inv = Investment.new(name: "New", ticker: "MGLU3", asset_type: "stock_br",
                           quantity: 10, avg_price: 700, user: users(:one))
      assert inv.save
      assert_equal 850, inv.current_price
    end
  end

  test "recalculate_from_trades computes correct avg_price" do
    inv = Investment.create!(name: "Test", ticker: "TEST", asset_type: "stock_br",
                             quantity: 0, avg_price: 0, user: users(:one))

    inv.trades.create!(user: users(:one), trade_type: "buy", quantity: 10, price: 2000, date: Date.today)
    inv.trades.create!(user: users(:one), trade_type: "buy", quantity: 10, price: 3000, date: Date.today)

    inv.recalculate_from_trades!
    assert_equal 20, inv.quantity
    assert_equal 2500, inv.avg_price
  end

  test "recalculate_from_trades handles sells" do
    inv = Investment.create!(name: "Test", ticker: "TEST", asset_type: "stock_br",
                             quantity: 0, avg_price: 0, user: users(:one))

    inv.trades.create!(user: users(:one), trade_type: "buy", quantity: 20, price: 2500, date: Date.today)
    inv.trades.create!(user: users(:one), trade_type: "sell", quantity: 5, price: 3000, date: Date.today)

    inv.recalculate_from_trades!
    assert_equal 15, inv.quantity
    assert_equal 2500, inv.avg_price
  end

  test "refresh_current_price! calls PriceService.fetch_price" do
    inv = investments(:one)
    old_price = inv.current_price

    stub_method(PriceService, :fetch_price, 50.0) do
      inv.refresh_current_price!
      assert_equal 5000, inv.reload.current_price
    end
  end

  test "refresh_current_price! does nothing when fetch_price returns nil" do
    inv = investments(:one)
    old_price = inv.current_price

    stub_method(PriceService, :fetch_price, nil) do
      inv.refresh_current_price!
      assert_equal old_price, inv.reload.current_price
    end
  end
end
