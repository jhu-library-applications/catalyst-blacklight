require 'test_helper'

# ExternalResourcesController - Testing public methods and response formats
class ExternalRecourcesTest < ActionDispatch::IntegrationTest
  def setup
    sfx_stub
  end

  test 'should render a show page' do
    get '/external_resources/show', params: { 'url_ver' => 'Z39.88-2004',
                                              'url_ctx_fmt' => 'info:ofi/fmt:kev:mtx:ctx',
                                              'ctx_ver' => 'Z39.88-2004',
                                              'ctx_tim' => '2021-04-27T10:42:48-05:00', 'ctx_id' => '',
                                              'ctx_enc' => 'info:ofi/enc:UTF-8', 'rft.genre' =>
                                              'journal', 'rft.issn' => '26378051',
                                              'rft.jtitle' => 'ACM transactions on computing for healthcare',
                                              'rft_val_fmt' => 'info:ofi/fmt:kev:mtx:journal',
                                              'rft_id' => 'https://catalyst-test.library.jhu.edu/catalog/bib_8730264',
                                              'rfr_id' => 'info:sid:library.jhu.edu/blacklight',
                                              'controller' => 'external_resources', 'action' => 'show' }

    assert_response :success
  end
end
