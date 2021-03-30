require 'test_helper'

class SolrDocumentTest < ActiveSupport::TestCase
  def setup
    WebMock.allow_net_connect!

    cat = Blacklight::SearchService.new(
      config: CatalogController.blacklight_config
    )
    _resp, @document = cat.fetch("bib_305929")
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
end
