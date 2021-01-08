# Just a place to store configuration information for local app code. 
# call JHConfig.params["whatever"] or JhConfig.params["whatever"] = whatever
module JHConfig
  def self.params
    @params ||= {}    
  end
end
