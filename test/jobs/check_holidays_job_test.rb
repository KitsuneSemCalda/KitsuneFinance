require "test_helper"

class CheckHolidaysJobTest < ActiveJob::TestCase
  test "performs without error" do
    CheckHolidaysJob.perform_now
    assert true
  end

  test "creates notifications when there are holidays today" do
    today = Date.today
    brasil_api_response = [{ "date" => today.iso8601, "name" => "Feriado Teste", "type" => "national" }]

    stub_method(BrasilApiService, :fetch_holidays, brasil_api_response) do
      assert_difference("Notification.count", User.count) do
        CheckHolidaysJob.perform_now
      end
    end
  end
end
