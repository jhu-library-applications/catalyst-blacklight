require 'multi_json'
require 'yaml'

class StackmapFetcher

  # fetcher = StackmapFetcher.new( holding )
  def initialize(holding)
    @holding = holding
  end

  stackmap_config_file = Rails.root + "config/stackmap_collections.yml"
  if File.exists? stackmap_config_file
    @@stackmap_collections = YAML.load_file( stackmap_config_file )
  else
    Rails.logger.warn("No stackmap config file found at #{stackmap_config_file}, no stack map buttons will be shown.")
    @@stackmap_collections = []
  end

  # Determines based on (right now) collection and location,
  # if we _probably_ have a map avail from Stackmap.
  #
  # fetcher = StackmapFetcher.new( holding )
  # map_available = fetcher.map_available?
  def map_available?
    return @holding && @holding.call_number && @holding.collection &&
      @holding.collection.internal_code && @@stackmap_collections.include?( @holding.collection.internal_code  )
  end

  # returns a MapInfo object OR nil if no map is available
  def fetch_map_info
    return nil unless @holding && @holding.call_number && @holding.collection.internal_code

    base_url = "https://jhu.stackmap.com/json/"
    item_call = CGI::escape(@holding.call_number)
    item_location = @holding.collection.internal_code
    # hard-coded, stackmap value for our account
    item_library = CGI::escape("Milton S. Eisenhower Librar")

    request_url = "#{base_url}?callno=#{item_call}&location=#{item_location}&library=#{item_library}"

    # stackmap = begin
    response  =  Faraday.get(request_url)

    if response.status != 200
      map_info = MapInfo.new(:status => "A #{response.status} response we received",
                             :error => "No map is available for this item at this time.")
    else
      response_body = response.body
      stackmap = MultiJson.load(response_body)

      if stackmap["stat"] != "OK"
        map_info = MapInfo.new(:status => stackmap["stat"],
                    :error => stackmap["message"])
      elsif stackmap["stat"]== "OK"
        if  stackmap["results"]["maps"].size > 0
          map_info = MapInfo.new(:status => stackmap["stat"],
                  :map_url => "#{stackmap["results"]["maps"].first["mapurl"]}&marker=1",
                  :floor_name => "#{stackmap["results"]["maps"].first["floorname"]}",
                  :range_name => "#{stackmap["results"]["maps"].first["ranges"].first["rangename"]}" )
        elsif stackmap["results"]["maps"].size == 0
          map_info = MapInfo.new(:status => "OK but no map",
                    :error => "No map is available for this item.")
        end
      end
    end

    return map_info
  end






  class MapInfo
    attr_accessor :map_url, :floor_name, :range_name, :status, :error



    # MapInfo.new(:image_url => "url', :range_name => "range name")
    def initialize(attributes = {})
      attributes.each_pair do |key, value|
        send("#{key}=", value)
      end

    end
  end


end
