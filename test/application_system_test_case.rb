require "test_helper"
require "axe-capybara"

AxeCapybara.configure(:default) do |c|
  # configuration options
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end
