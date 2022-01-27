require 'test_helper'

# Test the presenter directly, also tested indirectly through system tests
class OnlineAccessPresenterTest < ActiveSupport::TestCase
  def setup
    @presenter = OnlineAccessPresenter.new(targets: []).overflow
  end

  test 'supports external_links' do
    assert @presenter[:show_targets].kind_of? Array
  end
end
