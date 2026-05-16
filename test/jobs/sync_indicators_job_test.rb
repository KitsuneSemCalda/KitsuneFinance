require "test_helper"

class SyncIndicatorsJobTest < ActiveJob::TestCase
  test "performs without error" do
    SyncIndicatorsJob.perform_now
    assert true
  end

  test "fetches all indicators and exchange rates" do
    calls = []
    stub_method(IndicatorsService, :fetch_latest, ->(indicator) { calls << indicator; 13.75 }) do
      stub_method(ExchangeRateService, :fetch_rate, ->(from, to = "BRL") { calls << [from, to]; 5.20 }) do
        SyncIndicatorsJob.perform_now
      end
    end
    assert_includes calls, :selic
    assert_includes calls, :cdi
    assert_includes calls, :ipca
    assert_includes calls, ["USD", "BRL"]
    assert_includes calls, ["EUR", "BRL"]
  end
end
