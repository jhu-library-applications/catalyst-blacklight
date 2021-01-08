require 'test_helper'
require 'cgi'

class RequestsHelperTest < ActionView::TestCase

  test 'request_done_path - empty' do
    assert_equal(request_done_path, "/catalog")
  end

  test 'request_done_path - referrer good' do
    params["referer"] = 'http://localhost:3000/catalog/bib_305929'
    assert_equal(request_done_path, "/catalog")
  end

  test 'request_done_path - referrer bad' do
    params["referer"] = 'https://www.nytimes.com/interactive/2020/09/24/us/politics/how-to-vote-register.html'
    done_path = request_done_path
    uri = URI.parse(done_path)
    assert_nil(uri.host)
  end

  test 'request_done_path - ils_request' do
    Request = Struct.new(:bib_id)
    @ils_request = Request.new("305929")
    assert_equal(request_done_path, "/catalog/bib_305929")
  end

  test 'special_collection_request_url' do
    # Obtain doc
    cat = Blacklight::SearchService.new(
      config: CatalogController.blacklight_config
    )
    _resp, @document = cat.fetch("bib_305929")

    request_url = special_collection_request_url(@document, @document.to_holdings.first)
    uri = URI.parse(request_url)
    cgi = CGI::parse(uri.query)

    params_check = ['Action', 'Form', 'title', 'rfe_dat', 'callnumber', 'location', 'site', 'itemnumber', 'sublocation', 'ItemAuthor', 'ItemPlace', 'ItemDate']

    params_check.each do |param|
      assert_includes(cgi, param)
    end
  end
end
