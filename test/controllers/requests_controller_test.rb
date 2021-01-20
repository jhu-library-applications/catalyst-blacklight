require 'test_helper'

# RequestsController - Testing public methods and response formats
class RequestsControllerTest < ActionDispatch::IntegrationTest
  # No session - redirect to login
  test "no session - should redirect item request page" do
    get '/catalog/bib_305929/item/349606/request'
    assert_response :redirect
  end

  test "session - should render item request page" do
    skip "Horizon Unavailable" if horizon_unavailable?
    sign_in
    get '/catalog/bib_305929/item/349606/request'
    assert_response :success
  end
end
