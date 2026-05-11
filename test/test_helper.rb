ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "ostruct"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all

    def stub_method(klass, method, return_value = nil)
      original = klass.method(method)
      stub = return_value.is_a?(Proc) ? return_value : ->(*) { return_value }
      klass.define_singleton_method(method, stub)
      yield
    ensure
      klass.define_singleton_method(method, original)
    end
  end
end
