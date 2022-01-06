require 'test_helper'

class LocalCatalogHelperTest < ActionView::TestCase
  def setup
    WebMock.allow_net_connect!
    @document = SolrDocument.new(load_bib_json('bib_4839582'))
  end

  test 'related_links_type_helper helper can return online' do
    doc = {}
    doc['format'] = "Online"
    assert_equal(related_links_type(doc), :online)
  end

  test 'related_links_type_helper has a default value' do
    doc = {}
    doc['format'] = ["Print"]
    assert_equal(related_links_type(doc), :related)
  end

  test 'related_links_type_helper can return related' do
    doc = {}
    doc['format'] = ["Manuscript/Archive", "Print"]
    assert_equal(related_links_type(doc), :related)
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
