require 'test_helper'

class FaradayHelperTest < ActionView::TestCase

  def current_page?(arg)
    true
  end

  test 'Faraday can get urls' do
    response = Faraday.get('https://httpstat.us/200')
    assert_equal(response.status, 200)
  end

  test 'Faraday contiues on error' do
    response = Faraday.get('https://httpstat.us/500')
    assert_equal(response.status, 500)
  end

end
