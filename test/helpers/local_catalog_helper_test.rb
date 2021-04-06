require 'test_helper'

class LocalCatalogHelperTest < ActionView::TestCase
  def setup
    WebMock.allow_net_connect!

    @document = SolrDocument.new(load_bib_json('bib_4839582'))
  end

  test 'update_marc_for_citation helper' do
    assert_equal(@document.class, SolrDocument)

    marc = @document['marc_display']
    record = MARC::Reader.decode marc
    assert_nil(record['260'])

    @document = update_marc_for_citation(@document)
    marc = @document['marc_display']
    record = MARC::Reader.decode marc
    assert_not_nil(record['260'])
  end
end
