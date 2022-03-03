module MarcDisplay

  # Represents linking information for a piece of data to be displayed.
  # Attached to a Line
  class Link
      include DiscoverCallable
      attr_accessor :line
      
      @@default_link_text = "More"  


      def initialize(line, config_hash)
        @line = line
        config_hash = {} if config_hash == true
        if config_hash[:subfields].kind_of?(String)
          config_hash[:subfields] = config_hash[:subfields].split('') 
        end
        if config_hash[:link_text] == true
          config_hash[:link_text] = @@default_link_text
        end
        # default formatter, it just works better most of the time.
        # Can override with nil if you don't want it. 
        unless config_hash.has_key?(:formatter)
          config_hash[:formatter] = MarcDisplayLogic::DisplaySingleton.instance.method(:format_strip_edge_punctuation)
        end
        @config_hash = config_hash
      end
    
      def hash_for_url
        hash = {:controller => "catalog",
        :action => "index"}
        if ( facet = @config_hash[:facet])
          hash[:f] ||= {}
          hash[:f][facet] ||= []
          hash[:f][facet].push(query)
        else
          #ordinary query
          hash[:q] = query
          hash[:search_field] = @config_hash[:query_field] if @config_hash[:query_field]
        end
        
        # for JH Catalyst, we want all redirected links from record
        # to have :suppress_spellcheck=1 in them, to keep them from
        # being spellchecked. Sorry, more JH specific stuff is going in. 
        hash[:suppress_spellcheck] =1 

        # post-process with custom proc?

        if @config_hash[:custom]
          hash = @config_hash[:custom].call(self, hash)
          if hash.is_a?(Array)
            hash[:q] = hash[:q].sub(/""\s/, '')
          end
        end
          
       return hash
      end
    
      # Make the whole output line a link?
      def as_whole_line?    
        # if we have no suffix text, assume so
        link_text ? false : true
      end
    
      # Add the link on the end as a line suffix?
      def as_suffix?
        # only if we have suffix text    
        link_text ? true : false
      end
      
      # Text to use in link as seperate thing, if we're doing that
      def link_text
        @config_hash[:link_text]
      end
    
      def query
       unless (@query)
          
          # Default to just the same as the will be output,
          # but without any prefixes/suffixes
         @query = @line.parts.collect do |part|
           subject_overrider = SubjectOverrider.new(line: @line, part: part)
           
           if ( @config_hash[:subfields].nil? ||
                ((!part.marc_subfield.nil?) &&
                 @config_hash[:subfields].include?(part.marc_subfield.code)))
             
             subject_overrider.translated_subject
           end
         end.compact.join(" ")
         
         # Remove internal quote marks, they tend to result in not what
          # was intended, phrase search or not. 
          @query = clean_query(query)

          #Formatter?
          @query = @config_hash[:formatter].call(@query) if @config_hash[:formatter]
          
          @query = '"' + @query.gsub('"', '') + '"' if @config_hash[:phrase_search]
        end
        @query
      end
     
      # Cleans a query for redirection to Blacklight.
      # Currently that's just removing double quotes, but in a seperate
      # method so it can be called by custom link logic. 
      def clean_query(query)
        query.gsub(/\"/, '')  
      end

      
    end

end
