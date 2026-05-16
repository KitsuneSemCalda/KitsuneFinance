require "test_helper"

class InvestmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "index lists user investments" do
    get dashboard_investments_url
    assert_select "h2", text: "Investimentos"
  end

  test "new renders form fields" do
    get new_dashboard_investment_url
    assert_select "input[name='investment[ticker]']"
    assert_select "input[name='investment[quantity]']"
    assert_select "input[name='investment[avg_price]']"
  end

  test "create with manual prices converts cents correctly" do
    assert_difference("Investment.count") do
      post dashboard_investments_url, params: {
        investment: { name: "Teste", ticker: "TEST4", asset_type: "stock_br",
                      quantity: 10, avg_price: "25.50", current_price: "27.30" }
      }
    end
    inv = Investment.last
    assert_equal "Teste", inv.name
    assert_equal 2550, inv.avg_price
    assert_equal 2730, inv.current_price
    assert_equal @user, inv.user
    assert_redirected_to dashboard_investments_url
  end

  test "create without current_price fetches from service" do
    stub_method(PriceService, :fetch_price, ->(ticker, *, **) { ticker == "AUTO3" ? 30.0 : nil }) do
      assert_difference("Investment.count") do
        post dashboard_investments_url, params: {
          investment: { name: "Auto Price", ticker: "AUTO3", asset_type: "stock_br",
                        quantity: 5, avg_price: "10.00" }
        }
      end
    end
    inv = Investment.last
    assert_equal 1000, inv.avg_price
    assert_equal 3000, inv.current_price
  end

  test "update changes prices" do
    inv = investments(:one)
    patch dashboard_investment_url(inv), params: {
      investment: { avg_price: "30.00", current_price: "35.00" }
    }
    inv.reload
    assert_equal 3000, inv.avg_price
    assert_equal 3500, inv.current_price
    assert_redirected_to dashboard_investments_url
  end

  test "create fails with invalid data" do
    assert_no_difference("Investment.count") do
      post dashboard_investments_url, params: {
        investment: { name: "", asset_type: "stock_br", quantity: 1, avg_price: "10.00" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "destroy removes investment and cascades trades" do
    inv = investments(:one)
    Trade.create!(investment: inv, trade_type: "buy", quantity: 10, price: 2500, date: Date.today, user: @user)
    assert_difference("Investment.count", -1) { delete dashboard_investment_url(inv) }
    assert_equal 0, Trade.where(investment_id: inv.id).count
    assert_redirected_to dashboard_investments_url
  end

  test "cards view renders" do
    get cards_dashboard_investments_url
    assert_response :success
  end

  test "refresh_all_prices enqueues jobs for all investments" do
    assert_enqueued_jobs(@user.investments.count, only: InvestmentPriceRefreshJob) do
      post refresh_all_prices_dashboard_investments_url
    end
    assert_redirected_to dashboard_investments_url
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_investments_url
    assert_redirected_to new_user_session_path
  end
end