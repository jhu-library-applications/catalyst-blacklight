module MarcDisplay  

  module DiscoverCallable
    def callable?(obj)
      obj.kind_of?(Proc) || obj.kind_of?(Method)
    end
  end

  # Little module implementing a pattern where config can be given
  # at several levels, and given in a hash map. 
  # Including class needs to implement #map_key (a string key
  # that will be used to look up appropriate value in a formatter_map, 
  # label_map, etc) and #config_chain (an array of hashes that are config
  # values, starting at current, going to parent)
  module ConfigInvokeMapping
  
     def load_value_from_config(config_key, argument_to_pass = nil)
       found = nil
       config_chain.each do |config_hash|
         
         #if it's nil, forget it, onto next
         next if config_hash.nil?
         # specified directly with no map?
         break if (  found = config_hash[config_key]  )
         # map? onto next if we don't have a map and key
         next if map_key.nil?
         map = config_hash[:"#{config_key}_map"]
         next if map.nil?
         break if ( found = map[map_key]   )
         # try the universal wildcard in the map
         break if ( found = map["*"])
       end
       
       
       # Call if we need to call it
       if found && argument_to_pass && callable?(found)
          found = found.call(argument_to_pass)  
       end
     
       return found
     end
  end

  class FieldPresenter
    include DiscoverCallable  
  
    attr_accessor :lines, :config, :marc
    
  
    def initialize(solr_doc, marc, config)
  
      @config = config
      @marc = marc
      
      definition_list = normalize_definition(@config[:source])
      @lines = []
      definition_list.each do |spec|
  
    
      
        unless spec[:tag].nil?
          fields = marc.find_all do |field| 
                (spec[:tag].nil? || spec[:tag] === field.tag) &&
                
                (spec[:indicators][0].nil? || spec[:indicators][0] === field.indicator1 ) &&
                
                (spec[:indicators][1].nil? || spec[:indicators][1] === field.indicator2)                
          end
          
          # Add in corresponding 880's if present
          unless (spec[:suppress_non_roman] || @config[:suppress_non_roman])
            # stick linked fields in list right after corresponding original
            # field.
            fields = fields.collect do |orig_field|
                [orig_field].concat( find_linked_fields(orig_field) )
            end.flatten.compact
          end
  
          @lines.concat( fields.collect {|field| Line.new(@config, marc, field, spec)} )
        end

        if spec[:solr_field]
          value = solr_doc[spec[:solr_field]]  
          if ( value )
            # Might be string, might be array. normalize to array.
            value = [value] unless value.kind_of?(Array)
            value.each do |v|
              @lines << Line.new(@config, marc, nil, spec, :raw_data => v)
            end
          end
        end

      end

      # remove any lines that don't have any parts becuase there
      # were no matching candidates!
      @lines.reject! {|l| l.parts.length == 0}
  
      # unique if requested
      if (@config[:unique])
        lines_values_uniq!
      end
  
      # delete_if?
      
      @lines.delete_if do |line|
        (filter = line.delete_if_filter) &&   
           (filter.arity == 2 ?
            filter.call(line.marc_field, line) :
            filter.call(line.marc_field))
      end
      
    end
  
    # unique lines on their full parts in order
    def lines_values_uniq!
      hash = {}
      @lines.delete_if do |line|
        key = MarcDisplayLogic.instance.format_strip_edge_punctuation(line.parts.collect {|p| p.formatted_value}.join(" "))      
        if hash[key]        
          # delete
          true        
        else
          hash[key] = line
          # don't delete
          false
        end
      end
    end
    
    def custom_partial
      @config[:partial]
    end

    def render_with_helper
      @config[:render_with_helper]
    end
  
    def label  
      return @_label if defined?(@_label)
      
      @_label = @config[:label]        
      
      @_label = label.call(self) if callable?(label) 

      return @_label
    end
    

    # Output CSS classes to include in rendering of this field element
    def css_classes
      return @_classes if defined?(@_classes)
      
      @_classes = []
      @_classes.concat(@config[:css_classes]) if @config[:css_classes]
      (@_classes << @config[:id].to_s) if @config[:id]
      return @_classes
    end
    

    # Output raw CSS style to include in this field element, mostly
    # used for display:none when needed. 
    def style
      if ( lines.length == 0 && @config[:display_on_empty] == :hidden )
        "display:none"      
      else
        ""
      end
    end

    def should_display?
      return @_should_display if defined?(@_should_display)
      
      @_should_display = lines.length > 0 || [true, :hidden].include?(@config[:display_on_empty])
      return @_should_display
    end
    
  
    # turns a definition into an array of hashes, even if the original
    # used shortcuts. 
    def normalize_definition(definition)
      definition = [] if definition.nil?
      definition = [definition] unless definition.kind_of?(Array)
      # Parse out strings that are shortcuts for hashes and arrays, 
      # at several levels.  
      definition = definition.collect do |el|
        if el.kind_of?(String)
          el = {:load_marc => el}
        end
        if ( el[:load_marc] && el[:load_marc].kind_of?(String))
          # translate marc shortcut string to values        
          el[:load_marc] =~ /^(...)(-(..))?(.*)?/
          el.merge!({:tag => $1,
            :indicators => [($3[0..0] if ($3 && "*" != $3[0..0] )),          
                            ($3[1..1] if ($3 && "*" != $3[1..1] ))],
            :subfields =>  ($4 if $4)})
          el.delete(:load_marc)          
        end
        if el[:subfields].kind_of?(String)
            el[:subfields] = el[:subfields].split('')
        end
        el[:indicators] ||= [nil, nil]
        
        el                
      end
      definition
    end

    def find_linked_fields(orig_field, options = {})
      self.class.find_linked_fields(marc, orig_field, options)
    end
    
    def self.find_linked_fields(marc_doc, orig_field, options = {})
      return [] if orig_field.nil?
      
      if (linkage = orig_field['6'])
        marc_doc.find_all  do |f| 
          f.kind_of?(MARC::DataField) &&
          f['6'] && 
          f['6'][0..5] == "#{orig_field.tag}-#{linkage[4..5]}"
        end
      else
        []
      end      
    end

    # single field or nil
    def find_linked_field(orig_field, options = {})
      return find_linked_fields(orig_field, options)[0]
    end
    
  end

end
