# Test for SFX links
require 'test_helper'

class SfxLinksTest < ActiveSupport::TestCase
  def setup
    @open_url_query_string = { 'url_ver' => 'Z39.88-2004', 'url_ctx_fmt' => 'info:ofi/fmt:kev:mtx:ctx',
                               'ctx_ver' => 'Z39.88-2004', 'ctx_tim' => '2021-04-27T10:42:48-05:00', 'ctx_id' => '',
                               'ctx_enc' => 'info:ofi/enc:UTFg-8', 'rft.genre' => 'journal', 'rft.issn' => '26378051',
                               'rft.jtitle' => 'ACM transactions on computing for healthcare',
                               'rft_val_fmt' => 'info:ofi/fmt:kev:mtx:journal',
                               'rft_id' => 'https://catalyst.library.jhu.edu/catalog/bib_8730264',
                               'rfr_id' => 'info:sid:library.jhu.edu/blacklight',
                               'controller' => 'online_access', 'action' => 'show' }.to_query

    context_object = OpenURL::ContextObject.new_from_kev(@open_url_query_string)

    @good_sfx_links = SfxLinks.new(context_object: context_object)
    @bad_sfx_links = SfxLinks.new(context_object: OpenURL::ContextObject.new)
  end

  test 'that we receive a response from sfx' do
    skip '@TODO SSL Error'
    assert @good_sfx_links.links.present?
  end

  test 'that we can get a SFX url for making API requests' do
    skip '@TODO SSL Error'
    assert @good_sfx_links.sfx_url.match(/sfx.library.jhu.edu/)
  end

  test 'that we can make an HTTP request directly' do
    skip '@TODO SSL Error'
    assert @good_sfx_links.sfx_xml_request.match(/ctx_obj_set/)
  end

  test 'that we can get a unique string to use as a cache id' do
    base64_version_of_the_context_object_id =
      'WyJodHRwczovL2NhdGFseXN0LmxpYnJhcnkuamh1LmVkdS9jYXRhbG9nL2JpYl84NzMwMjY0Il0'
    assert_equal @good_sfx_links.cache_id, base64_version_of_the_context_object_id
  end
end
