# This class is initialized with a SolrDocument and provides
# formatted output for the view.
class SolrDocumentPresenter
    attr_reader :solr_document
  
    def initialize(solr_document:)
      @solr_document = solr_document
    end
  
    def finding_aid_link
      return unless solr_document.finding_aid_url.present?
  
      "Collection guide available: <a href='#{solr_document.finding_aid_url}'>#{solr_document.finding_aid_url}</a>"
    end
  
    def external_links
      MarcUrlPresenter.new(solr_document).link
    end
  
    def links
      finding_aid_link || external_links 
    end
  end
