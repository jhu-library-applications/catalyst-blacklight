if ActiveRecord::Base.connection.table_exists? 'flipper_features'
  require 'flipper'
  require 'flipper/adapters/active_record'

  Flipper.configure do |config|
    config.default do
      Flipper.new(Flipper::Adapters::ActiveRecord.new)
    end
  end

  # Features/Gates
  puts 'Flipper... start'
  puts 'Enabling: Navbar Banner Alert'
  Flipper[:navbar_banner_alert].enable

  puts 'Enabling: Navbar Book Pickups & Returns Page'
  Flipper[:navbar_pickup_page].enable

  puts 'Disbling: Reserves'
  Flipper[:reserves].disable

  puts 'Enabling: Curbside Mode'
  Flipper[:curbside_mode].enable
  puts '- Holdings => Hide TXT feature'
  puts '- Holdings => Enable "Request Pickup" buttons'
  puts '- Request  => Choose "Pickup Location"'
  puts '- Request  => Display pickup instructions'

  puts 'Flipper... end'
end
