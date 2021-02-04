source 'https://rubygems.org'

# use a .env file for environment variables in all enviroments
# we will no longer need this gem once we migrate to ansible
gem 'dotenv-rails'

gem 'rails', '~> 5.1'
# Use Puma as the app server
gem 'puma', '~> 4.1'

# Blacklight fixed to 7.0.1, change manually when you want to update
# blacklight.
gem 'blacklight', "= 7.11.1" #, :path => "../blacklight"
gem 'blacklight-marc', '= 7.0' # , :path => "../blacklight-marc"
gem 'rsolr', '~> 2.0'

#gem 'rake', "= 13.0.1"

gem 'kaminari'

gem 'marc', ">= 0.5.0"

# Not really a gem, but organized as a local gem, our marc
# mapping logic for display, checked in at ./marc_display
gem 'marc_display', :path => "./marc_display"

gem "blacklight_range_limit", "~> 7.0"
gem "blacklight_advanced_search", "~> 7.0" #,  :path => "../blacklight_advanced_search"

#gem "stackview_acorn_tester"

gem 'rails_stackview', :git => 'https://github.com/jhu-sheridan-libraries/rails_stackview', :branch => 'blacklight-7.0'
gem 'lcsort'

#gem 'rails_stackview' , :path => "vendor/rails_stackview"
#
#gem "rails_stackview", path: "vendor/rails_stackview"

gem 'borrow_direct', ">= 1.2.0.pre1", "< 2.0"  # for generating queries to BD

# gem "chosen_assets" #, :path => "../chosen-rails" # used to add fancy combo box UI to advanced search form facets
#gem 'chosen-rails' #  jquery multiselect plugin for advanced search

# gem "blacklight_cql", "~> 3.0"

# Removing Bento / EWL
# gem "bento_search", "~> 1.6" #, :github => "jrochkind/bento_search", :branch => "master"  # for multi-search support, article search, google site, etc.
# gem "celluloid", ">= 0.12.0" # used by bento_search for concurrent threaded fetching

gem "ipaddr_range_set"


gem "cql-ruby" #, :path => './cql-ruby'
#gem "formatted_rails_logger" # for allowing giving formatter to BufferedLogger with severity etc

gem "debugger", :group => :development, :platforms => [:mri_19]

gem 'openurl', '>= 0.1.0'

# httpclient should be removed at some point because the cert is expired an dappears to no longer be supported
gem 'httpclient'
gem 'faraday'
# Rails 4.2.4 doesn't allow mysql2 0.4 yet, change spec when
# a Rails is out that does.
# https://github.com/rails/rails/issues/21544
gem 'mysql2' , '~> 0.5'

# Newest versions of sprockets and sprockets-rails aren't succesfully
# compiling BL SASS due to some kind of bug. This is unfortunate,
# these following two lines should be removed when things resolved.
# https://github.com/rails/sprockets-rails/issues/279
#gem "sprockets-rails", ">= 2.3.0", "< 2.3.3"
#gem "sprockets", "~> 2.0"

gem 'multi_json', "~> 1.4"

gem 'sass-rails', " ~> 5.0", ">= 5.0.6"
gem "uglifier", ">= 1.3.0"
# gem 'coffee-rails', " ~> 4.2.0"
# gem "therubyracer", '~> 0.12.3', :platforms => :ruby

gem 'jquery-rails', '~> 4.3.5'
# gem 'bootstrap-sass'
gem 'bootstrap', '~> 4.0'

# Feature Flipping
gem 'flipper', '~> 0.19'
gem 'flipper-active_record'
gem 'flipper-ui'

# Capture application errors
gem 'exception_notification', '~> 4.4.0'
gem 'rollbar'

# Turn off those copious useless asset served lines in log in
# development.
#gem 'quiet_assets', :group => :development

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# Use unicorn as the web server
# gem 'unicorn'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end

gem 'webpacker', '~> 5.x'

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
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
  gem 'webdrivers'

  # Minitest
  gem 'minitest'
  gem "minitest-rails", "~> 5.2.0"
  gem 'database_cleaner'

  # Performance Tests
  gem 'rails-perftest'
  gem 'ruby-prof'

  # Code Coverage
  gem 'simplecov', require: false

  # Rack Session Access
  gem 'rack_session_access'
end

gem "rubycritic", require: false
gem 'rubocop-rails', require: false
gem 'rails_stats', require: false
gem 'inquisition', github: 'rubygarage/inquisition', group: %w(development test)
