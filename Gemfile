source 'https://rubygems.org'

# use a .env file for environment variables in all enviroments
# we will no longer need this gem once we migrate to ansible
gem 'dotenv-rails'

gem 'rails', '6.1.3.2'

# Use Puma as the app server
gem 'puma'

# Blacklight fixed to 7.0.1, change manually when you want to update
# blacklight.
gem 'blacklight', '= 7.19.0' # , :path => "../blacklight"
gem 'blacklight-marc', '= 7.0' # , :path => "../blacklight-marc"
gem 'rsolr', '~> 2.0'

gem 'kaminari'

gem 'marc', '>= 0.5.0'

# Not really a gem, but organized as a local gem, our marc
# mapping logic for display, checked in at ./marc_display
gem 'marc_display', path: './marc_display'

gem "blacklight_range_limit", "~> 7.0"
gem "blacklight_advanced_search", "~> 7.0" #,  :path => "../blacklight_advanced_search"
gem 'blacklight_unapi', :git => 'https://github.com/cul-it/blacklight-unapi', :branch => 'BL7-upgrade'

gem 'lcsort'

#gem 'rails_stackview' , :path => "vendor/rails_stackview"
#
#gem "rails_stackview", path: "vendor/rails_stackview"
gem 'rails_stackview', git: 'https://github.com/jhu-sheridan-libraries/rails_stackview', branch: 'rails-6'

gem 'borrow_direct', ">= 1.2.0.pre1", "< 2.0"  # for generating queries to BD

# gem "chosen_assets" #, :path => "../chosen-rails" # used to add fancy combo box UI to advanced search form facets
#gem 'chosen-rails' #  jquery multiselect plugin for advanced search

gem "blacklight_cql", git: 'https://github.com/jhu-library-applications/blacklight_cql.git', branch: 'bl-upgrade'

# Removing Bento / EWL
# gem "bento_search", "~> 1.6" #, :github => "jrochkind/bento_search", :branch => "master"  # for multi-search support, article search, google site, etc.
# gem "celluloid", ">= 0.12.0" # used by bento_search for concurrent threaded fetching

gem "ipaddr_range_set"


gem "cql-ruby" #, :path => './cql-ruby'
#gem "formatted_rails_logger" # for allowing giving formatter to BufferedLogger with severity etc

gem "debugger", :group => :development, :platforms => [:mri_19]

gem 'openurl', git: 'https://github.com/jhu-library-applications/openurl.git'

# httpclient should be removed at some point because the cert is expired an dappears to no longer be supported
gem 'httpclient'
gem 'faraday'


gem 'mysql2', '~> 0.5'
gem 'multi_json', '~> 1.4'
gem 'sass-rails', ' ~> 5.0', '>= 5.0.6'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails', '~> 4.3.5'
gem 'bootstrap', '~> 4.0'

# Feature Flipping
gem 'flipper', '~> 0.19'
gem 'flipper-active_record'
gem 'flipper-ui'

# Capture application errors
gem 'exception_notification', '~> 4.4.0'

# Cloud error monitors
gem 'appsignal'
gem 'sentry-rails'
gem 'sentry-ruby'

# For cron jobs
gem 'whenever', require: false

# Capistrano
gem 'capistrano', '~> 3.10', require: false
gem 'capistrano-chruby', require: false
gem 'capistrano-dotenv', require: false
gem 'capistrano-locally', require: false
gem 'capistrano-passenger', require: false
gem 'capistrano-rails', '~> 1.3', require: false
gem 'capistrano-yarn', require: false
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
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'solr_wrapper', '>= 0.3'

  # Traject
  # ex. traject -c traject/simple_marc_import.rb spec/fixtures/solr_documents/bib_1361354.marc
  #
  gem 'traject'
  gem 'traject_umich_format'

  gem 'rails_stats', require: false
  gem 'rubocop-rails', require: false
  gem 'rubycritic', require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'selenium-webdriver'
  gem 'webdrivers'

  # Minitest
  gem 'database_cleaner'
  gem 'minitest'
  gem 'minitest-rails', '~> 6.1.0'

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
