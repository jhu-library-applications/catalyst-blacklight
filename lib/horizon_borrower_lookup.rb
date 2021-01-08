  require 'nokogiri'
  require 'net/https'
  require 'uri'
    
class HorizonBorrowerLookup
  @@timeout = 1 # seconds
  
   

  def service_base
    @service_base ||= HipConfig.ws_base.chomp("/") + "/borrowers"
  end

  def fetch_with_auth(request_url)
    begin      
      uri = URI.parse(request_url)        
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = @@timeout
      http.open_timeout = @@timeout
      http.use_ssl = true if uri.scheme == "https"
      request = Net::HTTP::Get.new(uri.request_uri)
      
      if (auth = HipConfig.borrower_ws_auth)
        request.basic_auth(auth["username"], auth["password"])
      end
          
      response = http.request(request)
      
      response.value # will throw exception unless 200
    rescue Exception => e
      Rails.logger.error("\nHorizon lookup error: #{e.class} (#{e.message}), #{request_url.sub(/pin=\w+/, 'pin=[FILTERED]')} ")
      raise UnavailableError.new(e)
    end
      
    
    return response.body
    
  end
  
  # Args is a hash whose keys can be:
  # :id,  :second_id, :other_id, and/or pin.
  # Looks up the user against Horizon borrower web service.
  # Return a hash with nokogirl obj for borrower in key :xml, and
  # other useful attributes pulled out of the XML 
  # in other keys where available:
  # id, name, hopkinsID, jhedLID
  # Empty hash if nobody found.
  # Later we might create a model object for Borrower and return that,
  # for now hash is simple. 
  def lookup(args)
    request_url = service_base + '?' + args.to_query    
    
    first_borrower =  Nokogiri::XML(fetch_with_auth(request_url)).at('/borrowers/borrower')
    hash = nil
    if first_borrower
      hash = {}
      hash[:xml] = first_borrower
      hash[:name] = to_text( first_borrower.at('name') )
      hash[:barcode] = to_text(first_borrower.at('barcode'))
      hash[:pin] = to_text(first_borrower.at("pin"))
      hash[:horizon_borrower_id] = first_borrower['id']
      hash[:jhed_lid] = 
        to_text( first_borrower.at('other_ids/other_id[location="general"]') )
      #hopkinsID is tricky. What's in second_id is sometimes it, sometimes
      #not. We'll count it a hopkinsID if it looks like one.
      second_id = to_text( first_borrower.at('second_id') )
      if (second_id && second_id =~ /^[A-Z0-9]{6}$/)
        hash[:hopkins_id] = second_id
      end
    end
    
    return hash
    
  end

  def to_text(nokogiri_el)
    nokogiri_el ? nokogiri_el.inner_text : nil
  end
  
  class UnavailableError < StandardError 
    def initialize(e = nil, msg = "Sorry, a technical error with our system has occured, unable to lookup borrower account information.")
      super(msg)
      @original_exception = e
    end
    def original_exception
      @original_exception
    end
  end
  
end
