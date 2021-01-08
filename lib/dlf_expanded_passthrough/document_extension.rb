require 'nokogiri'
require 'open-uri'

require 'lcc_to_extra_label'

# Adds on a #to_dlf_expanded and #export_as_dlf_expanded to a 
# Blacklight::Solr::Document.
#
# In this implementation, "dlf_expanded" is actually a compacted version,
# that will only include 'top-level' holdings. If 'copies'/'holding
#
# Must define ils_di_base in extension_parameters. Also need  self_uri_prefix
# for request URL replacement. 

# eg:
#
# SolrDocument.extension_parameters[:ils_di_base] = "http://catalog.library.jhu.edu/ws/holdings"
# SolrDocument.extension_parameters[:self_uri_preifx] = "http://catalyst.library.jhu.edu/catalog/"
#  SolrDocument.use_extension(  DlfExpandedPassthrough::DocumentExtension ) do |document|
#   # Only documents with id's beginning 'bib_' are extended with this module
#    document["id"] =~ /^bib_/
#  end
module DlfExpandedPassthrough
  HttpTimeout = 5 # seconds. Yes, sometimes it takes this long, for reasons we do not understand. 
  module DocumentExtension
    
    def self.extended(document)
      document.will_export_as(:dlf_expanded, "application/xml")      
    end
  
    # Returns a nokogiri XML document representing a dlf_expanded
    # xml. NOTE: This is returning a shortened "direct only"
    # dlf expanded, with no items when there are holdingsets.
    # See also to_dlf_expanded_for_holdingset
    def to_dlf_expanded
      unless defined? @_to_dlf_expanded      
        @_to_dlf_expanded = enhance_dlf(Nokogiri::XML(dlf_lookup))
      end
      return @_to_dlf_expanded
    end

    
    def to_dlf_expanded_for_holdingset(copy_id)
      @per_copy_xml ||= {}
      url = dlf_base_url.chomp('/') + "/availability?id_type=copy&id=#{copy_id}"
      @per_copy_xml[copy_id] ||= begin
        enhance_dlf(Nokogiri::XML(DocumentExtension.safe_http_get(url)))      
      rescue OpenURI::HTTPError => e
        # Couldn't get the response from Horizon web service for some reason,
        # oh well, we have nothing. 
        Rails.logger.error("Error fetching from horizon availability service: #{e}: #{url}")
        nil
      end
    end
    
    # Returns a string
    def export_as_dlf_expanded
      # Not available? Could have been deleted from ILS, or could be an error.
      if to_dlf_expanded.nil?
         Rails.logger.warn("No dlf_expanded available for #{self["id"]}")
         return ""
      end
      
      # Take the <?xml ?> decleration off the top, so it won't mess
      # things up when it's embedded in the atom view.
      unless defined? @_export_as_dlf_expanded
        @_export_as_dlf_expanded = to_dlf_expanded.to_xml.sub(/^\s*\<\?xml [^>]*\?\>/, '')
      end
      return @_export_as_dlf_expanded
    end
    
    # The Solr id for documents from Horizon is the bibID prefixed by "bib_".
    # Remove the prefix. 
    def dlf_bibId
      self[:id].sub(/^bib_/, '')
    end
    # turns out this is more general purpose to transform to ils bib id from
    # Solr id, let's make it available under this name. 
    alias_method :ils_bib_id, :dlf_bibId

    # Utility method for internal use, but needs to be public so bulk_load
    # can call it.     
    # Change the dlf_expanded response provided by external service,
    # for instance replace request URLs to point at ourselves. Modifies
    # XML in-place, AND returns the xml node. Does not change data
    # attached to the receiver, this is a utility method. 
    #
    # Adds floor-level stuff into XML too. 
    def enhance_dlf(dlf)
     # Change request URL to be proper internally 
     dlf.xpath("./dlf:record/dlf:items/dlf:item/daia:daia/daia:document/daia:item/daia:available", dlf_xml_ns).each do |avail_node|         
       # walk up the path to get item_id and bib_id
       bib_id = avail_node.at_xpath("ancestor::dlf:item/marc:record/marc:controlfield[@tag=004]", dlf_xml_ns).text()
       item_id =  avail_node.at_xpath("ancestor::dlf:item", dlf_xml_ns)["id"]
       
       avail_node["href"]=  self.class.extension_parameters[:self_uri_prefix].chomp("/") + "/bib_" + bib_id + "/item/" + item_id + "/request"
     end
     
     # add in our collection label floor level processing
     (dlf.xpath("//dlf:holdingsrec", dlf_xml_ns) + dlf.xpath("//dlf:item", dlf_xml_ns)).each do |node|
       call_num = node.xpath("./marc:record/marc:datafield[@tag='852']/marc:subfield[@code='h']", dlf_xml_ns).inner_text
       collection_code = node.xpath("./ilsitem:description/ilsitem:collection/dc:identifier", dlf_xml_ns).inner_text
       
       if (extra = LCCToExtraLabel.translate( collection_code, call_num ))
         coll_node = node.at_xpath("./marc:record/marc:datafield[@tag='852']/marc:subfield[@code='c']", dlf_xml_ns)       
         local_coll_node = node.at_xpath("./ilsitem:description/ilsitem:collection/dc:title", dlf_xml_ns)
         
         label = coll_node ? coll_node.inner_text : ""
         
         # add extra info after 'Eisenhower', or at end of string if no 'Eisenhower'
         after = "Eisenhower"
         index = label.index(after)
         if index
           label = label.insert index+after.length, " #{extra}"
         else
           label = label + " #{extra}"
         end
         
         coll_node.content = label if coll_node
         local_coll_node.content = label if local_coll_node
       end
       
     end

     return dlf
    end
    
    protected
  
    def dlf_xml_ns
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
     
     # ruby open-uri doesn't let us set a read timeout, which we really
     # want when HIP is misbehaving. And ruby http stuff is weird in general.
     # we make all http calls through this method, so we can do em how we want.
     def self.safe_http_get(url)
       Timeout::timeout(DlfExpandedPassthrough::HttpTimeout) do
         return open(url).read
       end
     end
     

    
    # Lookup the response, return the string
    def dlf_lookup
      begin
        # includeItems=false means don't include the items when you've
        # got copies. Just top level. 
        url = dlf_base_url.chomp('/') + "/availability?id_type=bib&includeItems=false&id=#{dlf_bibId}" 
        DocumentExtension.safe_http_get(url)
      rescue Exception => e
        Rails.logger.error("Can't load DlfExpanded responses from Horizon: #{e.class} #{e.message}: #{url} ")
        raise e
      end
    end
    

    
    def dlf_base_url
      self.class.extension_parameters[:ils_di_base]
    end

    # A Method to bulk pre-load dlf-expanded responses for a list of documents.
    # Normally each document lazy loads it's response from foreign service
    # on demand. If you have a large list, this can get (in theory) expensive,
    # you may want to pre-load them all at once, using one single HTTP call.
    # I ran into confusion trying to benchmark this to see if it's really
    # needed, so I'm not positive, but it did appear to help.
    def self.bulk_load(documents)
      start_time = Time.now
      
      bib_ids = []
      doc_by_bib_id = {}

      # we'll pull the dlf_base_url from an arbitrary document
      # in our set. If differnet docs have different base urls, oh boy,
      # things will be bad. okay, we'll actually throw on that, why not. 
      dlf_base_url = nil 
      
      documents.each do |doc|
        # if they passed in a doc that doesn't have DlfExpandedPassthrough,
        # no prob, just skip it.
        next unless doc.respond_to?(:dlf_bibId)
        id = doc.send(:dlf_bibId).to_s
        bib_ids << id
        doc_by_bib_id[id] = doc

        raise Exception.new("bulk_load documents with different dlf_base_url's? Not going to work.") if ( (!dlf_base_url.nil?) && dlf_base_url != doc.send(:dlf_base_url) )
        dlf_base_url = doc.send(:dlf_base_url)
      end
      
      # no documents, or no documents with DlfExpandedPassthrough.  
      return if bib_ids.empty?

      url = dlf_base_url.chomp("/") + "/availability?id_type=bib&includeItems=false&id=#{bib_ids.join(",")}"
      Rails.logger.debug("bulk_load fetching #{url}")
      begin
        whole_xml = Nokogiri.XML(DocumentExtension.safe_http_get(url))
      
      
      
        records = whole_xml.xpath("dlf:collection/dlf:record", {"dlf" => "http://diglib.org/ilsdi/1.1"})
        # if only one item was included, it doesn't start with dlf:collection,
        # sigh.
        if (records.size == 0)
          records = whole_xml.xpath("dlf:record", {"dlf" => "http://diglib.org/ilsdi/1.1"})
        end
        
        records.each do |record|         
          # weird nokogiri hacking to put this in it's own XML document,
          # -- while preserving namespaces! Can't find any way to do it but
          # serialize and parse again, after setting attributes, bah.
          # to make matters worse, this seems to be neccesary only when record
          # is NOT the root element, and ruins things when it i
          unless (record == whole_xml.root)
            record.namespaces.each_pair do |attr, value|
              record[attr] = value            
            end
          end
          
          # warning don't use // in that xpath, or it'll get the first doc
          # in our result set, not off the current one. 
          bib_id = record.at_xpath("./dlf:bibliographic", {"dlf" => "http://diglib.org/ilsdi/1.1"}).attribute("id").to_s
          doc = doc_by_bib_id[bib_id]
  
          
          new_record_doc = Nokogiri::XML::Document.new
          new_record_doc.parse( record.to_xml ).first.parent = new_record_doc
          record = doc.enhance_dlf(new_record_doc)
  
        
  
          # set ivars so dlf_expanded response won't be lazy loaded later,
          # we've pre-loaded it. 
          doc.instance_variable_set("@_to_dlf_expanded", record  )        
          bib_ids.delete(bib_id)
        end
      rescue Exception => e
        Rails.logger.error("Can't bulk load DlfExpanded responses from Horizon: #{e.class} #{e.message}")
      end
      

      # any bib_ids we didn't find any records for, set to nil, to 
      # prevent lazy lookup later, lookup later isn't going to get anything
      # either.
      bib_ids.each do |orphaned_id|
        doc_by_bib_id[orphaned_id].instance_variable_set("@_to_dlf_expanded", nil)
      end                
      
      Rails.logger.info("DlfExpandedPassthrough::DocumentExtension.bulk_load (#{documents.length} bibs) (#{"%.1f" % ((Time.now.to_f - start_time.to_f) * 1000)})")      
    end
    
  end

  # Add this module to a SolrHelper to turn on bulk loading
  # Eg: 
  # CatalogController.class_eval do
  #   include DlfExpandedPassthrough::BulkLoad
  # end
  #
  module BulkLoad
    # And over-ride new version for BL 5.10+ and 6.x
    def search_results(*)
      (response, doc_list) = super

      DlfExpandedPassthrough::DocumentExtension.bulk_load(doc_list)

      return [response, doc_list]
    end
 
  end
end
