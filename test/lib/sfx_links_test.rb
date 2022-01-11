# Test for SFX links
require 'test_helper'

class SfxLinksTest < ActiveSupport::TestCase
  def setup
    @open_url_query_string = { 'url_ver' => 'Z39.88-2004', 'url_ctx_fmt' => 'info:ofi/fmt:kev:mtx:ctx',
                               'ctx_ver' => 'Z39.88-2004', 'ctx_tim' => '2021-04-27T10:42:48-05:00', 'ctx_id' => '',
                               'ctx_enc' => 'info:ofi/enc:UTFg-8', 'rft.genre' => 'journal', 'rft.issn' => '26378051',
                               'rft.jtitle' => 'ACM transactions on computing for healthcare',
                               'rft_val_fmt' => 'info:ofi/fmt:kev:mtx:journal',
                               'rft_id' => 'https://catalyst-test.library.jhu.edu/catalog/bib_8730264',
                               'rfr_id' => 'info:sid:library.jhu.edu/blacklight',
                               'controller' => 'online_access', 'action' => 'show' }.to_query

    context_object = OpenURL::ContextObject.new_from_kev(@open_url_query_string)

    @good_sfx_links = SfxLinks.new(context_object: context_object)
    @bad_sfx_links = SfxLinks.new(context_object: OpenURL::ContextObject.new)
  end

  test 'that we receive a response from sfx' do
    assert @good_sfx_links.links.present?
  end

  test 'that we at get an empty array if there are no results' do
    assert_equal @bad_sfx_links.links, []
  end

  test 'that we can get a SFX url for making API requests' do
    assert_equal @good_sfx_links.sfx_url, 'https://sfx-stage.library.jhu.edu/sfxlcl41?url_ver=Z39.88-2004&url_ctx_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Actx&ctx_ver=Z39.88-2004&ctx_tim=2021-04-27T10%3A42%3A48-05%3A00&ctx_id=&ctx_enc=info%3Aofi%2Fenc%3AUTFg-8&rft.action=show&rft.controller=online_access&rft.genre=journal&rft.issn=26378051&rft.jtitle=ACM+transactions+on+computing+for+healthcare&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&rft_id=https%3A%2F%2Fcatalyst-test.library.jhu.edu%2Fcatalog%2Fbib_8730264&rfr_id=info%3Asid%3Alibrary.jhu.edu%2Fblacklight&sfx.ignore_date_threshold=1&sfx.response_type=multi_obj_xml'
  end

  test 'that we can make an HTTP request directly' do
    assert @good_sfx_links.sfx_xml_request.match(/ctx_obj_set/)
  end

  test 'that we can get a unique string to use as a cache id' do
    base64_version_of_the_context_object_id =
      'WyJodHRwczovL2NhdGFseXN0LXRlc3QubGlicmFyeS5qaHUuZWR1L2NhdGFsb2cvYmliXzg3MzAyNjQiXQ'
    assert_equal @good_sfx_links.cache_id, base64_version_of_the_context_object_id
  end
end
