require 'test_helper'

# Test the presenter directly
class RequestFailurePresenterTest < ActiveSupport::TestCase
  def setup
    @message = "You can't request this online; please ask library staff about a copy through other local libraries."
    @new_message = "You can’t request this item. Please ask library staff about using it in the library or for help locating another copy."
    @exception = OpenStruct.new({ message: @message })
    @presenter = RequestFailurePresenter.new(exception: @exception)
  end

  test 'supports external_links' do
    assert_equal @presenter.message, @new_message
  end
end
