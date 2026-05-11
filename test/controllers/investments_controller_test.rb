require "test_helper"

class InvestmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get dashboard_investments_url
    assert_response :success
  end

  test "should get new" do
    get new_dashboard_investment_url
    assert_response :success
  end

  test "should create investment with manual prices" do
    assert_difference("Investment.count") do
      post dashboard_investments_url, params: {
        investment: {
          name: "Teste",
          ticker: "TEST4",
          asset_type: "stock_br",
          quantity: 10,
          avg_price: "25.50",
          current_price: "27.30"
        }
      }
    end

    inv = Investment.last
    assert_equal "Teste", inv.name
    assert_equal 2550, inv.avg_price
    assert_equal 2730, inv.current_price
    assert_redirected_to dashboard_investments_url
  end

  test "should create investment without manual current_price" do
    stub_method(PriceService, :fetch_price, 30.0) do
      assert_difference("Investment.count") do
        post dashboard_investments_url, params: {
          investment: {
            name: "Auto Price",
            ticker: "AUTO3",
            asset_type: "stock_br",
            quantity: 5,
            avg_price: "10.00"
          }
        }
      end
    end

    inv = Investment.last
    assert_equal "Auto Price", inv.name
    assert_equal 1000, inv.avg_price
    assert_equal 3000, inv.current_price
  end

  test "should update investment" do
    inv = investments(:one)

    patch dashboard_investment_url(inv), params: {
      investment: {
        avg_price: "30.00",
        current_price: "35.00"
      }
    }

    inv.reload
    assert_equal 3000, inv.avg_price
    assert_equal 3500, inv.current_price
    assert_redirected_to dashboard_investments_url
  end

  test "should not create investment with invalid data" do
    assert_no_difference("Investment.count") do
      post dashboard_investments_url, params: {
        investment: { name: "", asset_type: "stock_br", quantity: 1, avg_price: "10.00" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should destroy investment" do
    assert_difference("Investment.count", -1) do
      delete dashboard_investment_url(investments(:one))
    end
    assert_redirected_to dashboard_investments_url
  end

  test "should redirect when not authenticated" do
    sign_out @user
    get dashboard_investments_url
    assert_redirected_to new_user_session_url
  end
end
