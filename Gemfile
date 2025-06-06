source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"
gem "rails", "~> 8.0.1"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", "~> 6.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"
gem 'sidekiq'
gem "redis", "~> 4.0"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false
gem 'devise'
gem 'pundit'
gem 'httparty'
gem 'chartkick'
gem 'groupdate'
gem 'highcharts'
gem 'sass-rails', '>= 6'
gem 'sassc-rails'
gem 'bootstrap', '~> 5.3'
gem 'finnhub_ruby', '~> 1.1'
gem 'whenever', require: false
gem 'kaminari'

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem 'pry'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :development do
  gem "web-console"
  gem "bullet"
  gem "spring"
  gem "spring-watcher-listen"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "database_cleaner-active_record"
  gem "shoulda-matchers"
  gem "webmock"
  gem "vcr"
  gem "capybara-screenshot"
  gem "rails-controller-testing"
end
