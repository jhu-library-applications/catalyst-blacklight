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
