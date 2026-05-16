require "test_helper"

class IndicatorsServiceTest < ActiveSupport::TestCase
  test "fetch_latest returns selic value" do
    response = OpenStruct.new(success?: true, body: '[{"valor": "14.25"}]')
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_equal 14.25, IndicatorsService.fetch_latest(:selic)
    end
  end

  test "fetch_latest returns cdi value" do
    response = OpenStruct.new(success?: true, body: '[{"valor": "13.65"}]')
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_equal 13.65, IndicatorsService.fetch_latest(:cdi)
    end
  end

  test "fetch_latest returns ipca value" do
    response = OpenStruct.new(success?: true, body: '[{"valor": "0.38"}]')
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_equal 0.38, IndicatorsService.fetch_latest(:ipca)
    end
  end

  test "fetch_latest returns nil for unknown indicator" do
    assert_nil IndicatorsService.fetch_latest(:unknown)
  end

  test "fetch_latest returns nil on failed request" do
    response = OpenStruct.new(success?: false)
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_nil IndicatorsService.fetch_latest(:selic)
    end
  end

  test "fetch_latest returns nil on network error" do
    stub_method(Faraday, :get, ->(*) { raise Faraday::Error }) do
      assert_nil IndicatorsService.fetch_latest(:selic)
    end
  end

  test "fetch_latest returns nil on invalid JSON" do
    response = OpenStruct.new(success?: true, body: "invalid")
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_nil IndicatorsService.fetch_latest(:selic)
    end
  end
end
