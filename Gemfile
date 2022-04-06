source 'https://rubygems.org'

ruby '~> 2.6.6'

# use a .env file for environment variables in all enviroments
# we will no longer need this gem once we migrate to ansible
gem 'dotenv-rails'

gem 'rails', '~> 6.1'

# Use Puma as the app server
gem 'puma'

# Blacklight fixed to 7.0.1, change manually when you want to update
# blacklight.
gem 'blacklight', "= 7.11.1" #, :path => "../blacklight"
gem 'blacklight-marc', '= 7.1.1' # , :path => "../blacklight-marc"
gem 'rsolr', '~> 2.0'

gem 'kaminari'

gem 'marc', ">= 0.5.0"

# Not really a gem, but organized as a local gem, our marc
# mapping logic for display, checked in at ./marc_display
gem 'marc_display', :path => "./marc_display"

gem "blacklight_range_limit", "~> 8.0"
gem "blacklight_advanced_search", :git => 'https://github.com/jhu-library-applications/blacklight_advanced_search', :branch => 'master'
gem "blacklight_cql", :git => 'https://github.com/jhu-library-applications/blacklight_cql', :branch => 'bl-upgrade'

gem 'blacklight_unapi', :git => 'https://github.com/jhu-library-applications/blacklight-unapi', :branch => 'master'


gem 'rails_stackview', :git => 'https://github.com/jhu-sheridan-libraries/rails_stackview', :branch => 'rails-6'
gem 'lcsort'


gem 'borrow_direct', ">= 1.2.0.pre1", "< 2.0"  # for generating queries to BD



gem "ipaddr_range_set"


gem "cql-ruby" #, :path => './cql-ruby'

gem "debugger", :group => :development, :platforms => [:mri_19]

gem 'openurl', git: 'https://github.com/jhu-library-applications/openurl.git'

# httpclient should be removed at some point because the cert is expired an dappears to no longer be supported
gem 'httpclient'
gem 'faraday'

gem 'mysql2'


gem 'multi_json', "~> 1.4"

gem 'sass-rails', " ~> 5.0", ">= 5.0.6"
gem "uglifier", ">= 1.3.0"


gem 'jquery-rails', '~> 4.3.5'

gem 'bootstrap', '~> 4.0'

# Feature Flipping
gem 'flipper', '~> 0.19'
gem 'flipper-active_record'
gem 'flipper-ui'

# Capture application errors
gem 'exception_notification', '~> 4.4.0'


gem 'sentry-rails'
gem 'sentry-ruby'
gem 'appsignal'

# For cron jobs
gem 'whenever', require: false

gem 'capistrano', '~> 3.10', require: false
gem 'capistrano-chruby', require: false
gem 'capistrano-dotenv', require: false
gem 'capistrano-passenger', require: false
gem "capistrano-rails", "~> 1.3", require: false
gem 'capistrano-yarn', require: false
gem 'capistrano-locally', require: false

gem 'bcrypt_pbkdf'
gem 'ed25519'

gem 'webpacker', '5.4.3'

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
  gem 'rubocop-rails', require: false
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'debride'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'solr_wrapper', '>= 0.3'

  # Traject
  # ex. traject -c traject/simple_marc_import.rb spec/fixtures/solr_documents/bib_1361354.marc
  #
  gem 'traject'
  gem 'traject_umich_format'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'capybara-screenshot'

  # Minitest
  gem 'minitest'
  gem "minitest-rails", "~> 6.1"
  gem 'database_cleaner'

  # Performance Tests
  gem 'rails-perftest'
  gem 'ruby-prof'

  # Code Coverage
  gem 'simplecov', require: false
  gem 'simplecov-cobertura'

  # Rack Session Access
  gem 'rack_session_access'

  # Used for mocking HTTP requests in tests
  gem 'webmock'
end

