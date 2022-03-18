
module DlfExpandedPassthrough
  
  # A Blacklight::Solr::Document extension that adds a #to_holdings
  # method to documents, that, based on #to_dlf_expanded, will create
  # Holdings models (defined in this file). Requires a document to
  # have #to_dlf_expanded, so will normally be applied to the same
  # documents as the DlfExpandedPassthrough::DocumentExtension module.
  #
  # dlf_expanded results are still very flexible, this won't neccesarily
  # work with _any_ of em, tries to work with the data types included
  # in the HorizonItemInfo Servlet. 
  # http://code.google.com/p/horizon-holding-info-servlet/wiki/ResponseFormats
  #
  #  Array returned by #holdings will include ONLY <holdingset>s if any
  # <holdingset>s are present, else items if any <item>s are present.
  # <item>s are not included if there are <holdingsets>. TBD, has_children?
  # method and way to fetch children. 
  #  
  # SolrDocument.extension_parameters[:ils_di_base] =   
        "http://catalog.library.jhu.edu/ws/holdings"

  # SolrDocument.use_extension( DlfExpandedPassthrough::ToHoldingsExtension) do |document|
  #   document.respond_to?(:to_dlf_expanded)
  # end
  
  module ToHoldingsExtension   
    
    def to_holdings
      unless defined? @_to_holdings
        bench_start = Time.now
        
        begin
          if to_dlf_expanded.nil?
            # bulk_load tried and failed to load, putting a nil here instead.
            # Error message was already logged, all we can do is give em
            # the error holdings message.                     
            return fake_error_holdings
          else
            orig_xml = to_dlf_expanded.at_xpath("dlf:record", ToHoldingsExtension.xml_namespaces) #nokogiri assumed
          end
        rescue Exception => e
          Rails.logger.error("Could not fetch holdings for #{self["id"]}, #{e.class} #{e.message}")          
          return fake_error_holdings
        end
  
        return [] unless orig_xml
  
        holdings = []
  
        list = orig_xml.xpath("dlf:holdings/dlf:holdingset/dlf:holdingsrec", ToHoldingsExtension.xml_namespaces)
        if list.length == 0
          # try items
          list = orig_xml.xpath("dlf:items/dlf:item", ToHoldingsExtension.xml_namespaces)
        end
        
        
        list.each do |entity|
            h = Holding.new
  
            fill_in_holding_from_xml(h, entity)
            
            next if suppress_holding?(h)
            
            holdings << h     
        end              
  
        Rails.logger.debug("to_holdings id=#{self[:id]}(#{"%.1f" % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")
        
        @_to_holdings = holdings
      end
      return @_to_holdings
    end


    def to_holdings_for_holdingset(copy_id)
      @per_copy_holdings ||= {}
      @per_copy_holdings[copy_id] ||= begin
        orig_xml = to_dlf_expanded_for_holdingset(copy_id)        
        if orig_xml
          list = orig_xml.xpath("dlf:record/dlf:items/dlf:item", ToHoldingsExtension.xml_namespaces)
          holdings = []
          list.each do |entity|
            h = Holding.new

            fill_in_holding_from_xml(h, entity)
            
            next if suppress_holding?(h)
            
            holdings << h     
          end
        end
        holdings
      end
    end



    # fetch a single item, return Holding object. 
    # Used in request page, to check an item's details to see if we need
    # to apply custom logic to the request form. 
    def self.fetch_item_holding(item_id)
      # Yeah, hardcoded SolrDocument isn't great, but this whole
      # architecture has become a mess. 
      begin
        base = SolrDocument.extension_parameters[:ils_di_base]
        url = base.chomp("/") + "/availability?id_type=item&id=#{item_id}"
        noko = Nokogiri::XML(DlfExpandedPassthrough::DocumentExtension.safe_http_get(url))
      
        h = Holding.new
        
        # check if nil
        item = noko.at_xpath("dlf:record/dlf:items/dlf:item", DlfExpandedPassthrough::ToHoldingsExtension.xml_namespaces) 
        
        return fake_error_holdings.first if item.nil?
        
        fill_in_holding_from_xml(h, item)
      rescue Exception => e
        Rails.logger.error("Could not load item with id #{self["id"]}, #{e.class} #{e.message}")
        
        return fake_error_holdings.first
      end
                            
      return h
    end

    def self.xml_namespaces
      {
        "dlf" => "http://diglib.org/ilsdi/1.1",
        "marc" => "http://www.loc.gov/MARC21/slim",
        "daia" => "http://ws.gbv.de/daia/",
        "atom" => "http://www.w3.org/2005/Atom",
        "opensearch" => "http://a9.com/-/spec/opensearch/1.1/",
        "ilsitem" => "http://purl.org/NET/ils-holdings-schema/1",
        "dc" => "http://purl.org/dc/elements/1.1/"
      }  
    end

    protected
    
    # Create a placeholder 'holding' object that just states there
    # was an error, real holdings can't be fetched. Return that, in
    # an array.
    def fake_error_holdings
        fake_holding = Holding.new
        fake_holding.collection.display_label = "Error fetching holdings!"
        return [fake_holding]
    end

    
    # Just instance method conveneince on class method. 
    def fill_in_holding_from_xml(holding, xml_entity)
       DlfExpandedPassthrough::ToHoldingsExtension.fill_in_holding_from_xml(holding, xml_entity)  
    end

    # receives a holdingset or item xml element (nokogiri), tries
    # to extract various details from it, trying several different places,
    # to fill in a holdings record. Mutates holding record passed in. 
    def self.fill_in_holding_from_xml(holding, xml_entity)

      holding.has_children = true if xml_entity.name == "holdingsrec"

      # for now, we consider all Items and no Copies requestable, just
      # like we have HIP set up.
      holding.requestable = true if xml_entity.name != "holdingsrec"

      holding.id = first_non_blank_xpath(xml_entity,
        "dlf:simpleavailability/dlf:identifier",
        "marc:record/marc:controlfield[@tag='001']"        
      ) || xml_entity.attribute("id")
      
      holding.location.display_label =        
          first_non_blank_xpath(xml_entity,
          "marc:record/marc:datafield[@tag='852']/marc:subfield[@code='b']",
          "ilsitem:description/ilsitem:location/dc:title",
          "daia:daia/daia:document/daia:item/daia:department",
          "dlf:simpleavailability/dlf:location"
          )
      holding.location.internal_code =
        first_non_blank_xpath(xml_entity, "ilsitem:description/ilsitem:location/dc:identifier")
      
      

      holding.collection.display_label =          
        first_non_blank_xpath(xml_entity,
        "marc:record/marc:datafield[@tag='852']/marc:subfield[@code='c']",
        "ilsitem:description/ilsitem:collection/dc:title",
        "daia:daia/daia:document/daia:item/daia:storage"
        )
      holding.collection.internal_code = 
        first_non_blank_xpath(xml_entity, "ilsitem:description/ilsitem:collection/dc:identifier")                        
      

      holding.call_number = first_non_blank_xpath(xml_entity,               "marc:record/marc:datafield[@tag='852']/marc:subfield[@code='h']",
      "daia:daia/daia:document/daia:item/daia:label"
      )
          
      holding.copy_string = first_non_blank_xpath(
        xml_entity,
        "marc:record/marc:datafield[@tag='852']/marc:subfield[@code='i']"
      )

      holding.notes << first_non_blank_xpath(xml_entity,               "marc:record/marc:datafield[@tag='852']/marc:subfield[@code='z']")
      holding.notes.compact!
             
      
      holding.status.internal_code = first_non_blank_xpath(xml_entity, "ilsitem:description/ilsitem:itemStatus/dc:identifier")
      holding.status.dlf_expanded_code = first_non_blank_xpath(xml_entity, "dlf:simpleavailability/dlf:availabilitystatus")
      holding.status.display_label = first_non_blank_xpath(xml_entity, 
        "dlf:simpleavailabilty/dlf:availabilitymsg",
        "ilsitem:description/ilsitem:itemStatus/dc:title"
      )
      #holding.status.display_label = "Multiple items" if holding.status.display_label.blank? && holding.has_children?

      due_date_str = first_non_blank_xpath(xml_entity, "dlf:simpleavailability/dlf:dateavailable") 
      if due_date_str
        if due_date_str =~ /T/
          #it's got a time, use DateTime
          holding.due_date =  DateTime.strptime(due_date_str, "%Y-%m-%dT%H:%M:%S")  
        else
          holding.due_date = Date.strptime(due_date_str, '%Y-%m-%d') 
        end        
      end
      
      xml_entity.xpath("marc:record/marc:datafield[@tag='866' or @tag='867' or @tag='868']", ToHoldingsExtension.xml_namespaces).each do |marc_run_statement|
        holding.run_statements << Holding::Run.new( 
          :marc_type => marc_run_statement.attribute("tag").to_s,
          :display_statement => first_non_blank_xpath(marc_run_statement, "marc:subfield[@code='a']"),
          :note => first_non_blank_xpath(marc_run_statement, "marc:subfield[@code='z']")
        )
      
      end
      
      #localInfo is where we keep barcode and rmst, using Horizon
      # column names: ibarcode ; moravia_rmst      
      xml_entity.xpath("ilsitem:description/ilsitem:localInfo", ToHoldingsExtension.xml_namespaces).each do |node|
        holding.localInfo[ node["key"].to_s ] = node.text
      end

      return holding
    end
    

    #JHU-specific logic, some holdings we'd like to suppress, because
    # they are fake internet 'holdings'. 
    def suppress_holding?(holding)
      # there are way too many collection codes involved, so we actually
      # filter based on display label -- many times one display label
      # has a dozen or more collection codes. 
      ! (["Welch Online Journal", "Internet", "Internet resource", "Electronic Resources -- Welch Medical Library", "Welch Online Journals", "Gibson - Electronic Journals", "Gibson-Electronic Books or Documents", "Internet resource", "Online Book", "Friedheim -- Electronic Access", "OCLC Electronic Collections Online", /Electronic Resource/i, /Online Book/i ].find {|test| test === holding.collection.display_label  }).nil?
    end
    
    
    # first arg is a nokogiri xml element. Rest of args are xpaths.
    # will return first non-blank string value found.
    # returns nil if none found. 
    def self.first_non_blank_xpath(*args)
      xml = args[0]
      xpaths = args[1..args.length+1]
      xpaths.each do |xpath|
        value = xml.at_xpath(xpath, ToHoldingsExtension.xml_namespaces)
        return value.text unless value.blank?
      end
      return nil
    end
    
    
  end

  
end
