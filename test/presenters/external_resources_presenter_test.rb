require 'test_helper'

# Test the presenter directly, also tested indirectly through system tests
class ExternalResourcesPresenterTest < ActiveSupport::TestCase
  def setup
    @presenter = ExternalResourcesPresenter.new(urls: []).overflow
  end

  test 'supports external_links' do
    assert @presenter[:show_urls].kind_of? Array
  end
end
