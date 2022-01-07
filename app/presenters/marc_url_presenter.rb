# This class allows you to retrieve a URL string
# from a SolrDocument's 856 MARC field. It also
# allows you to prefix the URL with the EZProxy's
# base URL.

class MarcUrlPresenter
    attr_reader :solr_document, :marc_electronic_location, :marc_url
  
    def initialize(solr_document)
      @solr_document = solr_document
      @marc_electronic_location = solr_document.to_marc['856']
      @marc_url = marc_electronic_location.try(:[], 'u')
    end
  
    def link
      return '' unless @marc_url.present?
  
      "<a href='#{url}'>#{hostname}</a>"
    end
  
    private
  
    def hostname
      URI(marc_url.strip).host
    end
  
    def url
      "#{ezproxy_prefix}#{marc_url}"
    end
  
    def ezproxy_prefix
      ENV['EZPROXY_PREFIX'] 
    end
  end
