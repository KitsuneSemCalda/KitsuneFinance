require "test_helper"

class ApplicationRecordTest < ActiveSupport::TestCase
  test "is an abstract class" do
    assert ApplicationRecord.abstract_class
  end
end
