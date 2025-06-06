# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
require 'webdrivers'

# Configure webdrivers to use a specific chromedriver version
# This avoids the error with Chrome Beta/Dev versions
Webdrivers::Chromedriver.required_version = '114.0.5735.90'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
require 'devise'
require 'warden'
require 'shoulda/matchers'
require 'database_cleaner/active_record'
# Add additional requires below this line. Rails is not loaded until this point!
require 'webmock/rspec'
require 'capybara/rspec'
require 'pundit/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

# Configure ActiveJob to use test adapter
ActiveJob::Base.queue_adapter = :test

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
    # Allow WebMock to pass through certain connections for JS tests
    allowed_sites = [
      'chromedriver.storage.googleapis.com',
      'localhost',
      '127.0.0.1',
      'gvt1.com'
    ]
    
    if WebMock.respond_to?(:disable_net_connect!)
      WebMock.disable_net_connect!(
        allow_localhost: true,
        allow: allowed_sites
      )
    end
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  # Include Devise test helpers for controller specs
  config.include Devise::Test::ControllerHelpers, type: :view

  # Include Devise test helpers in request specs
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :feature

  # Warden test helpers
  config.include Warden::Test::Helpers
  
  config.before(:each) do
    Devise.mappings[:user] = Devise.mappings[:user] || Devise.add_mapping(:user, {})
  end

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/7-0/rspec-rails
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.before(:each) do
    stub_request(:get, %r{https://finnhub.io/api/v1/quote}).to_return(
      status: 200,
      body: {
        'c' => 150.0,
        'h' => 155.0,
        'l' => 145.0,
        'o' => 148.0,
        't' => Time.current.to_i,
        'v' => 1000000
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  # Set default host for tests
  config.before(:each, type: :controller) do
    @request.host = 'localhost:3000'
  end

  config.before(:each, type: :request) do
    host! 'localhost:3000'
  end

  config.before(:each, type: :system) do
    driven_by(:rack_test)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
