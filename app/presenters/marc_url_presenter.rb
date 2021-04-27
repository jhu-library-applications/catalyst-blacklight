# This class allows you to retrieve a URL string
# from a SolrDocument's 856 MARC field
class MarcUrlPresenter
  attr_reader :solr_document, :marc_electronic_location

  def initialize(solr_document)
    @solr_document = solr_document
    @marc_electronic_location = solr_document.to_marc['856']
  end

  def link
    "<a href='#{url}'>#{hostname}</a>"
  end

  private

  def hostname
    URI(marc_url.strip).host
  end

  def url
    "#{ENV['EZPROXY_PREFIX']}#{marc_url}"
  end

  def marc_url
    marc_electronic_location['u']
  end
end
