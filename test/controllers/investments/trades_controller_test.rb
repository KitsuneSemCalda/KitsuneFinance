require "test_helper"

class Investments::TradesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:one)
    @investment = investments(:one)
  end

  test "should get index" do
    get dashboard_investment_trades_path(@investment)
    assert_response :success
  end

  test "should create trade" do
    assert_difference("Trade.count", 1) do
      post dashboard_investment_trades_path(@investment), params: {
        trade: { trade_type: "buy", quantity: 10, price: 25.50, date: Date.today }
      }
    end
    assert_redirected_to dashboard_investment_trades_path(@investment)

    @investment.reload
    assert @investment.quantity > 0
  end

  test "should not create invalid trade" do
    assert_no_difference("Trade.count") do
      post dashboard_investment_trades_path(@investment), params: {
        trade: { trade_type: "invalid", quantity: 10, price: 25.50, date: Date.today }
      }
    end
    assert_redirected_to dashboard_investment_trades_path(@investment)
  end

  test "should get edit" do
    trade = trades(:one)
    get edit_dashboard_investment_trade_path(@investment, trade)
    assert_response :success
  end

  test "should update trade" do
    trade = trades(:one)
    patch dashboard_investment_trade_path(@investment, trade), params: {
      trade: { quantity: 20 }
    }
    assert_redirected_to dashboard_investment_trades_path(@investment)

    @investment.reload
    assert_equal 25, @investment.quantity
  end

  test "should destroy trade" do
    trade = trades(:one)
    assert_difference("Trade.count", -1) do
      delete dashboard_investment_trade_path(@investment, trade)
    end
    assert_redirected_to dashboard_investment_trades_path(@investment)
  end

  test "should clear all trades" do
    assert_difference("Trade.count", -@investment.trades.count) do
      delete clear_dashboard_investment_trades_path(@investment)
    end
    assert_redirected_to dashboard_investment_trades_path(@investment)
  end

  test "should not access another user's trades" do
    other_investment = investments(:three)
    get dashboard_investment_trades_path(other_investment)
    assert_response :not_found
  end

  test "should refresh price" do
    post refresh_price_dashboard_investment_path(@investment)
    assert_redirected_to dashboard_investments_path
  end
end
