module MarcDisplay

  # A single line of output, usually corresponding to a marc field
  # Composed of a list of LinePart's. 
  class Line
    include DiscoverCallable
    include ConfigInvokeMapping
  
    attr_accessor :marc_field, :marc_record, :raw_data
    
  
    def initialize(config, marc_record, marc_field, spec, options ={})
      @config_hash = config
      @marc_record = marc_record
      @marc_field = marc_field
      @data_spec = spec
      @raw_data = options[:raw_data]
    end
  
    def parts
      unless @parts
        if ( @marc_field )
          subfields = if @data_spec[:subfields].nil?
                          @marc_field.subfields
                      else
                        @marc_field.find_all {|sf| @data_spec[:subfields].include?(sf.code)}
                      end
          @parts = subfields.collect {|sf| LinePart.new(@data_spec, @marc_field, sf, self)}
        else 
          @parts = [ LinePart.new(@data_spec, nil, nil, self, :raw_data => @raw_data) ]
        end      
      end
      @parts
    end
  
    def map_key
      if @marc_field
        # Use the real tag the 880 represents      
        @marc_field.tag == '880' ? @marc_field['6'][0..2] : @marc_field.tag
      else
        return nil
      end
    end
  
    # used by ConfigInvokeMapping
    def config_chain
      @config_chain ||= [@data_spec, @config_hash]
    end
    
    def prefix
      return @_prefix if defined?(@_prefix)
      @_prefix = load_value_from_config(:prefix, @marc_field)  
    end
    


    def label
      if defined? @_label
        return @_label 
      else
        return (@_label = load_value_from_config(:label, @marc_field))
      end
    end
    
    
    def delete_if_filter
      if defined? @_delete_if_filter
        return @_delete_if_filter
      else
        return (@_delete_if_filter = load_value_from_config(:delete_if_filter))
      end
    end    
  
    def css_classes
      return @_classes if defined?(@_classes)
      
      @_classes = []
      @_classes.concat(@config_hash[:css_classes]) if @config_hash[:css_classes]
      @_classes.push( "marc#{@marc_field.tag}" ) if @marc_field 
      return @_classes
    end
  
    def link
      #debugger if marc_field && marc_field.tag == "19"
      unless (@link || @link == false)
        link_config = @data_spec[:link].nil? ? @config_hash[:link] : @data_spec[:link]  
        if link_config
          @link = Link.new( self, link_config )
        else
          @link = false
        end
      end
      # @link == false means there was no link to load. 
      @link == false ? nil : @link
    end
  
    def join(seperator = " ")
      @parts.collect {|p| p.formatted_value }.join(seperator)
    end
  end

end
