require 'test_helper'

class FaradayHelperTest < ActionView::TestCase

  def current_page?(arg)
    true
  end

  test 'Faraday can get urls' do
    response = Faraday.get('https://catalyst.library.jhu.edu')
    assert_equal(response.status, 200)
  end

  test 'Faraday continues on error' do
    response = Faraday.get('https://catalyst.library.jhu.edu/catalog?title=%22&search_field=advanced&commit=Search')
    assert_equal(response.status, 404)
  end

end
