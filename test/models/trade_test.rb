require "test_helper"

class TradeTest < ActiveSupport::TestCase
  test "valid trade" do
    trade = Trade.new(user: users(:one), investment: investments(:one),
                      trade_type: "buy", quantity: 10, price: 2500, date: Date.today)
    assert trade.valid?
  end

  test "invalid without trade_type" do
    trade = Trade.new(user: users(:one), investment: investments(:one),
                      quantity: 10, price: 2500, date: Date.today)
    assert_not trade.valid?
  end

  test "invalid trade_type" do
    trade = Trade.new(user: users(:one), investment: investments(:one),
                      trade_type: "invalid", quantity: 10, price: 2500, date: Date.today)
    assert_not trade.valid?
  end

  test "invalid without quantity" do
    trade = Trade.new(user: users(:one), investment: investments(:one),
                      trade_type: "buy", price: 2500, date: Date.today)
    assert_not trade.valid?
  end

  test "quantity must be positive" do
    trade = Trade.new(user: users(:one), investment: investments(:one),
                      trade_type: "buy", quantity: -1, price: 2500, date: Date.today)
    assert_not trade.valid?
  end

  test "invalid without price" do
    trade = Trade.new(user: users(:one), investment: investments(:one),
                      trade_type: "buy", quantity: 10, date: Date.today)
    assert_not trade.valid?
  end

  test "invalid without date" do
    trade = Trade.new(user: users(:one), investment: investments(:one),
                      trade_type: "buy", quantity: 10, price: 2500)
    assert_not trade.valid?
  end

  test "recalculates investment avg_price on create" do
    inv = investments(:two)
    inv.trades.destroy_all

    Trade.create!(user: users(:one), investment: inv,
                  trade_type: "buy", quantity: 10, price: 1000, date: Date.today)
    inv.reload
    assert_equal 10, inv.quantity
    assert_equal 1000, inv.avg_price

    Trade.create!(user: users(:one), investment: inv,
                  trade_type: "buy", quantity: 10, price: 2000, date: Date.today)
    inv.reload
    assert_equal 20, inv.quantity
    assert_equal 1500, inv.avg_price
  end

  test "recalculates investment on destroy" do
    inv = investments(:one)
    inv.trades.destroy_all

    t1 = Trade.create!(user: users(:one), investment: inv,
                       trade_type: "buy", quantity: 10, price: 1000, date: Date.today)
    t2 = Trade.create!(user: users(:one), investment: inv,
                       trade_type: "buy", quantity: 10, price: 2000, date: Date.today)
    inv.reload
    assert_equal 20, inv.quantity
    assert_equal 1500, inv.avg_price

    t1.destroy
    inv.reload
    assert_equal 10, inv.quantity
    assert_equal 2000, inv.avg_price
  end

  test "sell reduces quantity but does not affect avg_price" do
    inv = investments(:one)
    inv.trades.destroy_all

    Trade.create!(user: users(:one), investment: inv,
                  trade_type: "buy", quantity: 20, price: 1500, date: Date.today)
    Trade.create!(user: users(:one), investment: inv,
                  trade_type: "sell", quantity: 5, price: 1800, date: Date.today)
    inv.reload
    assert_equal 15, inv.quantity
    assert_equal 1500, inv.avg_price
  end
end
