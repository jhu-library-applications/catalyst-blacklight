require 'test_helper'

# RequestsController - Testing public methods and response formats
class RequestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    request_confirm_stub
  end

  # No session - redirect to login
  test "no session - should redirect item request page" do
    get '/catalog/bib_305929/item/349606/request'
    assert_response :redirect
  end

  test "session - should render item request page" do
    sign_in
    get '/catalog/bib_305929/item/349606/request'
    assert_response :success
  end
end
