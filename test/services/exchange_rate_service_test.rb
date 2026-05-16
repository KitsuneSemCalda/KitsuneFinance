require "test_helper"

class ExchangeRateServiceTest < ActiveSupport::TestCase
  test "responds to fetch_rate" do
    assert_respond_to ExchangeRateService, :fetch_rate
  end

  test "fetch_rate returns nil for invalid pair" do
    assert_nil ExchangeRateService.fetch_rate("INVALID", "XXX")
  end

  test "fetch_rate returns a positive float for USD-BRL" do
    rate = ExchangeRateService.fetch_rate("USD", "BRL")
    if rate
      assert_kind_of Float, rate
      assert_operator rate, :>, 0
    end
  end
end
