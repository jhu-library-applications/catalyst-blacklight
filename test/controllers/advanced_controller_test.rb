require 'test_helper'

# AdvancedController - Testing public methods and response formats
class AdvancedControllerTest < ActionDispatch::IntegrationTest
  test "should render advanced search" do
    get '/advanced'
    assert_response :success
  end

  test "should NOT render unicorn" do
    assert_raises(AbstractController::ActionNotFound) do
      get '/advanced/unicorn'
    end
  end
end
