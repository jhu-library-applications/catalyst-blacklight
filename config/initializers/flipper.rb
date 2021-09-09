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
  Flipper[:navbar_banner_alert].disable

  puts 'Enabling: Navbar Book Pickup Service Page'
  Flipper[:navbar_pickup_page].enable

  puts 'Disabling: Reserves'
  Flipper[:reserves].enable

  Flipper[:reserves_wirc].enable
  Flipper[:reserves_sssres].disable
  Flipper[:reserves_ewcrsv].disable
  Flipper[:reserves_ecolrsv].disable
  Flipper[:reserves_emcrsv].disable
  Flipper[:reserves_eres].enable

  puts 'Disabling: TXT Feature'
  Flipper[:txt].disable

  puts 'Disabling: Curbside Mode'
  Flipper[:curbside_mode].disable
  puts '- Holdings => Enable "Request Pickup" buttons'
  puts '- Request  => Choose "Pickup Location"'
  puts '- Request  => Display pickup instructions'

  puts 'Flipper... end'
end
