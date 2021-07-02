require 'test_helper'

class SolrDocumentPresenterTest < ActiveSupport::TestCase
  def setup
    WebMock.allow_net_connect!

    cat = Blacklight::SearchService.new(
      config: CatalogController.blacklight_config
    )
    _resp, @document = cat.fetch("bib_305929")

    @archive_document = SolrDocument.find('bib_1929587')
  end

  test 'supports external_links' do
    assert SolrDocumentPresenter.new(solr_document: @document).respond_to? :external_links
  end

  test 'that we can display a finding aid link' do
    assert_equal "Collection guide available: <a href='http://aspace.library.jhu.edu/repositories/3/resources/898'>http://aspace.library.jhu.edu/repositories/3/resources/898</a>",
    SolrDocumentPresenter.new(solr_document: @archive_document).finding_aid_link
  end
end
