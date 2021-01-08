# Some class-level methods for reading the config/hip.yml initializer
# with HIP url info
class HipConfig
  include Singleton
  
  def parsed_yaml
    #Run config file threw ERB before loading the YAML
		@parsed_yaml ||= YAML.load(ERB.new(File.read("config/hip.yml")).result)
  end
  def self.parsed_yaml
    self.instance.parsed_yaml
  end
  
  def self.host
    parsed_yaml[Rails.env]["host"]    
  end
  
  def self.borrower_ws_auth
    parsed_yaml[Rails.env]["borrower_ws_auth"]
  end
  
  def self.ipac_base
    "https://#{host}/ipac20/ipac.jsp"
  end
  
  # the 'items out' and borrowers web service servlet we install
  # on our hip servers. Or can be specified in hip.yml as an alternate
  # location. 
  def self.ws_base
    if (ws_direct = parsed_yaml[Rails.env]["web_service_url"])
      ws_direct
    else
      "https://#{host}/ws"
    end
  end
  
  # can be a lot faster to access than the https one, for multiple
  # accesses, if you're accessing a web service that doesn't require
  # https
  def self.ws_base_not_secure
    ws_base.sub(/^https/, 'http')
  end
  
end
