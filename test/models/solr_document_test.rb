require 'test_helper'

class SolrDocumentTest < ActiveSupport::TestCase
  def setup
    WebMock.allow_net_connect!

    cat = Blacklight::SearchService.new(
      config: CatalogController.blacklight_config
    )
    _resp, @document = cat.fetch('bib_305929')

    @book_document = SolrDocument.find('bib_6383327')
    @archive_document = SolrDocument.find('bib_1929587')
  end

  test 'supports marc_display' do
    assert @document.respond_to? :to_marc
  end

  test 'supports holdings' do
    assert @document.respond_to? :to_holdings
  end

  test 'supports dlf_expanded' do
    assert @document.respond_to? :to_dlf_expanded
  end

  test 'supports export_as_dlf_expanded' do
    assert @document.respond_to? :export_as_dlf_expanded
  end

  test 'that we can safely and easily access a possible isbn' do
    assert_equal '1305633946', @book_document.isbn
  end

  test 'that we can safely and easily access a possible finding aid link' do
    assert_equal 'http://aspace.library.jhu.edu/repositories/3/resources/898', @archive_document.finding_aid_url
  end
end
