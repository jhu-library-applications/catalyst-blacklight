class SolrDocumentPresenter
  attr_reader :solr_document

  def initialize(solr_document:)
    @solr_document = solr_document
  end

  def finding_aid_link
    return '' unless solr_document.finding_aid_url.present?

    "Collection guide available: <a href='#{solr_document.finding_aid_url}'>#{solr_document.finding_aid_url}</a>"
  end

  def external_links
    url_presenter = MarcUrlPresenter.new(solr_document)
    url_presenter.link
  end

  def links
    external_links || finding_aid_link
  end
end
