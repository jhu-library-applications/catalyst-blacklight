require 'test_helper'

# MultiSearchController - Testing public methods and response formats
class MultiSearchControllerTest < ActionDispatch::IntegrationTest
  test 'old homepage redirects' do
    get '/multi_search'
    assert_response :redirect
  end

  test 'old search articles engine redirects' do
    get '/search/articles', params: {
      q: 'kerouac',
      utf8: '✓',
      search_field: 'all_fields'
    }
    assert_response :redirect
  end
end
