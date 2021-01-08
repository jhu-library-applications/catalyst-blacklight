require 'ostruct'

class IlsStatus
  # load the yaml into an array
  @@list = []
  structure = YAML.load_file(File.join(Rails.root, "config", "ils_status_descriptions.yml"))

  structure.each_pair do |label, values|
     # labels need to be unique in our current system, we'll just turn the label
     # into an id. "id" is sort of a reserved word, so "identifier" 
     item = OpenStruct.new(values.merge("display_label" => label, "identifier" => label.downcase.parameterize))
     # explanation is allowed to include HTML, mark it html_safe
     item.explanation = item.explanation.html_safe if item.explanation
     @@list << item
  end

  def self.list
    @@list
  end

  # returns an OpenStruct of info
  def self.find_by_id(id)
    @@list.find {|item| item.identifier == id}
  end
  
  # returns an OpenStruct of info
  def self.find_by_holding(holding, options = {})
    options.reverse_merge!(:default_fallback => true)

    # first try by code
    description = @@list.find do |item|
      item.item_status_codes && item.item_status_codes.include?( holding.status.internal_code )
    end
    # if no luck, try by description
    unless description
      description = @@list.find do |item|
        desc_label = item.display_label.downcase
        
        query_label = if holding.status && holding.status.display_label
          holding.status.display_label.downcase
        else
          "ERROR"
        end
          
        desc_label.index(query_label) == 0 || query_label.index(desc_label) == 0
                    
      end      
    end
    # otherwise default, unless description set to 'false'
    if description.blank? && options[:default_fallback] && description != false
      description = @@list.find {|item| item.display_label == "DEFAULT"}
    end

    return description
  end

  
end
