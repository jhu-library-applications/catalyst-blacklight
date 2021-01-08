module MarcDisplay
  # Contained in a MarcDisplay::Line
  # usually correspond to a single subfield. 
  class LinePart
    include DiscoverCallable
    include ConfigInvokeMapping
  
    attr_accessor :marc_field, :marc_subfield  
  
    def initialize(config_hash, marc_field, subfield, line, options = {})
      
      @config_hash = config_hash
      @marc_field = marc_field
      @marc_subfield = subfield
      @line = line
      @raw_data = options[:raw_data]
    end
  
    def value
      if @raw_data
        value = @raw_data
      else
        value = @marc_subfield.value
      end     
    end
    
    def config_chain
      [@config_hash].concat(@line.config_chain)
    end
    
    def map_key
      if (@marc_field && @marc_subfield)
        if @marc_field.tag == '880'
          # use the value of the corresponding tag!
          return "#{@marc_field['6'][0..2]}#{@marc_subfield.code}"
        end
      
        return "#{@marc_field.tag}#{@marc_subfield.code}"
      else
        return nil
      end
    end
    
    def formatted_value
      if defined? @_formatted_value
        return @_formatted_value
      else
        return (@_formatted_value = (load_value_from_config(:formatter, value) || value))
      end
    end    
  
    
    def prefix
      if defined?(@_prefix)
        return @_prefix
      else
        return (@_prefix = load_value_from_config(:prefix, @marc_subfield))
      end
    end
    

    def raw_prefix
      if defined? @_raw_prefix
        return @_raw_prefix
      else
        return (@_raw_prefix = load_value_from_config(:raw_prefix, @marc_subfield))
      end
    end
    
    
    def label
      if defined? @_label
        return @_label
      else
        return (@_label = load_value_from_config(:label, @marc_subfield))
      end
    end
    
  
    def css_classes
      if defined? @_classes
        return @_classes
      else
        @_classes = []
        @_classes.concat(@config_hash[:css_classes]) if @config_hash && @config_hash[:css_classes]
        @_classes.push("marc#{@marc_field.tag}_#{@marc_subfield.code}") if @marc_field && @marc_subfield    
        return @_classes
      end
    end
    
  end

end
