require 'hip_config'
require 'dlf_expanded_passthrough/document_extension'
require 'dlf_expanded_passthrough/to_holdings_extension'

class SolrDocument 

  include Blacklight::Solr::Document
      # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_ss
  extension_parameters[:marc_format_type] = :marcxml
  use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( SolrDocument.extension_parameters[:marc_source_field] )
  end
  
  field_semantics.merge!(    
                         :title => "title_ssm",
                         :author => "author_ssm",
                         :language => "language_ssim",
                         :format => "format"
                         )


  
  # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type] = :marc21
  use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( :marc_display  )
  end

  def has_volumes
    exists = false
    status = ''

    self.to_holdings.each do |holding|
      ray('Holding: ', holding)
      if holding.has_children?
        # TODO: I really only need to check the current item not hte whole set at this point, but I need to know if this specific holding is a volume
        holding = self.to_holdings_for_holdingset(holding.id).find {|h| h.id == params[:item_id]}
        if self.to_holdings_for_holdingset(holding.id).find {|h|
          h.copy_string.include?('v.')
        }
          exists = true
          status = h.status.try(:display_label)
        end
      else
        if ! holding.copy_string.nil? && holding.copy_string.include?('v.')
          exists = true
          status = holding.status.try(:display_label)
        end
      end
    end

    [exists, status]
  end

  def fetch_holding(item_id)
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

  # Custom hack to unescape Marc21 control characters that
  # SolrMarc escapes weirdly, and somehow were automatically unescaped in
  # Solr 1.4, but no longer using Solr 4.3. I don't understand it. This is a mess.
  # This is no longer needed when we stop using SolrMarc, or stop storing in binary Marc21,
  # or both. 
  module LoadMarcEscapeFix
    def load_marc
      if _marc_format_type.to_s == "marc21"
        value = fetch(_marc_source_field)
                
        # SolrMarc escapes binary marc control chars like this, we need to
        # unescape. Yes, we might theroetically improperly unescape literals too.
        # it's a hell of a system. 
        value.gsub!("#29;", "\x1D")
        value.gsub!("#30;", "\x1E")
        value.gsub!("#31;", "\x1F")

        return MARC::Record.new_from_marc( value )
      else
        return super
      end
    end
  end
  use_extension(LoadMarcEscapeFix) do |document|
    document.key?( :marc_display )
  end
  
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Document::DublinCore)    
  field_semantics.merge!(    
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :publisher => "published_display",
                         :format => "format"
                         )

  # Custom JH stuff

  # Setup and register extension to provide better Marc to OpenURL mapping,
  # from the MarcDisplay plugin
  SolrDocument.extension_parameters[:rfr_id] = "info:sid:library.jhu.edu/blacklight"
  SolrDocument.extension_parameters[:self_uri_prefix] = "#{APP_CONFIG['catalyst_base_url']}/catalog/"
  begin
    SolrDocument.use_extension(MarcDisplay::Blacklight::MarcToOpenUrlExtension) do |document|
      document.respond_to?(:to_marc)
    end
  end

  # dlf-expanded format passthrough
  begin
    SolrDocument.extension_parameters[:ils_di_base] =  HipConfig.ws_base_not_secure + "/holdings"
    #broken with 6
    SolrDocument.use_extension(  DlfExpandedPassthrough::DocumentExtension ) do |document|
      document["id"] =~ /^bib_/
    end
    # and add #to_holdings method too, based on dlf-expanded.
    SolrDocument.use_extension( DlfExpandedPassthrough::ToHoldingsExtension) do |document|
       document.respond_to?(:to_dlf_expanded)
    end
  end


end
