Catalyst::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Do not compress assets
  config.assets.compress = false
  config.assets.css_compressor = :sass
  config.assets.digest = !!ENV['DIGEST_ASSETS']

  # Expands the lines which load the assets
  config.assets.debug = true

  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { :host => 'catalyst.library.jhu.edu' }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :user_name => ENV['SMTP_USER_NAME'],
    :password => ENV['SMTP_PASSWORD'],
    :address => ENV['SMTP_ADDRESS'],
    :domain => ENV['SMTP_DOMAIN'],
    :port => ENV['SMTP_PORT'],
    :authentication => :plain
  }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

	# Google Analytis tracking code farooqsadiq.com
	# TODO how do you us config in layouts?
	# As a workaround, I am using an ENV
  config.tracker = "UA-1581694-2"
  ENV["GOOGLE_ANALYTICS"] = config.tracker
end
