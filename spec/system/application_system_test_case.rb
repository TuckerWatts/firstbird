require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, options: { browser: :remote, url: ENV.fetch("SELENIUM_DRIVER_URL") }

  include Devise::Test::IntegrationHelpers

  def setup
    super
    driven_by :selenium, using: :headless_chrome, options: { browser: :remote, url: ENV.fetch("SELENIUM_DRIVER_URL") }
  end
end 