require 'capybara/rspec'
require 'capybara/rails'
require 'capybara-screenshot/rspec'

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1000')
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :selenium_chrome_headless

Capybara::Screenshot.register_driver(:selenium_chrome_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  "screenshot_#{example.description.gsub(' ', '-').gsub(/^.*\/spec\//,'')}"
end

RSpec.configure do |config|
  config.before(:each, type: :feature) do
    Capybara.reset_sessions!
  end

  # Configure Capybara screenshot
  config.after(:each, type: :feature) do |example|
    if example.exception
      Capybara::Screenshot.screenshot_and_open_image
    end
  end

  # Delete screenshots after each test
  config.after(:each) do
    if Capybara::Screenshot.autosave_on_failure
      Dir.glob(Rails.root.join('tmp/capybara/screenshot_*.png')).each do |file|
        File.delete(file)
      end
    end
  end
end 