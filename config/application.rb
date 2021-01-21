require File.expand_path('../boot', __FILE__)

require 'rails/all'


# Turn on deprecations from Blacklight in logs, so we can deploy
# to staging and check logs.
if Rails.env.demo? || Rails.env.development?
  require 'deprecation'
  Deprecation.default_deprecation_behavior = :log
  $stderr.puts "Logging Deprecations from Blacklight and Deprecation gem..."
  ActiveSupport::Deprecation.debug = true
end

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
if defined?(Bundler)
  Bundler.require(:default, Rails.env)
end



module Catalyst
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # avoid rails 4.0 deprecation message
    I18n.enforce_available_locales = false

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    config.filter_parameters += [:pin]

    # Sibley hospital runs IE9 forced into compatibility view; we're trying to override
    # to turn off compatibility view, so the bootstrap will display okay
    # https://github.com/h5bp/html5-boilerplate/blob/v4.0.0/doc/html.md#x-ua-compatible
    #
    # meta http-equiv tag in html did not seem to be working for us, let's try it with
    # actual headers.
    config.action_dispatch.default_headers.merge!({
        'X-UA-Compatible' => 'IE=edge,chrome=1'
    })

    config.action_dispatch.default_headers = {
        'X-Frame-Options' => 'ALLOW-FROM https://jhu.libwizard.com/'
    }

    # Enable the asset pipeline
    config.assets.enabled = true

    # More top-level assets that need to be included in app?
    #config.assets.precompile += ['print.css']
    require 'custom_log_formatter'
    config.log_formatter = CustomLogFormatter.new


    # Default SASS Configuration, check out https://github.com/rails/sass-rails for details
    config.assets.compress = !Rails.env.development?
    config.sass.line_comments = Rails.env.development?



    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # email from address used for emails and email-to-SMS of bibs sent out
    # of catalyst.
    ActionMailer::Base.default :from => '"Johns Hopkins Libraries" <ask@jhu.libanswers.com>'

    # temporarily suppress browse until our index is built
    #config.x.suppress_browse = true

    # Exception Handling
    config.exceptions_app = self.routes
  end
end
