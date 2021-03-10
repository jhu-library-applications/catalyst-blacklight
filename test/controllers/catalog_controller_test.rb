require 'test_helper'

# CatalogController - Testing public methods and response formats
class CatalogControllerTest < ActionDispatch::IntegrationTest
  test "should render catalog homepage" do
    get '/catalog'
    assert_response :success
  end

  test "should return json results" do
    get '/catalog', params: { format: 'json' }
    assert_response :success
    assert_equal 'application/json', response.content_type

    json = JSON.parse(response.body)
    refute_empty json["data"]
  end

  # @TODO: Need to load data for shelfbrowse
  test "should render shelfbrowse" do
    get '/shelfbrowse'
    assert_response :success
  end

  # Shelf Browse
  test "should render a single shelfbrowse_item" do
    get '/shelfbrowse_item', params: { id: 'bib_324680' }
    assert_response :success
  end

  # Email - No Login
  test "no session - should render email action" do
    get '/catalog/bib_324680/email'
    assert_response :redirect
  end

  # Email - Login
  test "session - should render email action" do
    skip "Horizon Unavailable" if horizon_unavailable?
    sign_in
    get '/catalog/bib_324680/email'
    assert_response :success
  end

  # Citation
  test "should render citation action" do
    get '/catalog/bib_324680/citation'
    assert_response :success
  end

  # SMS / Auth
  test "should redirect sms action to login" do
    get '/catalog/bib_8039975/sms/9369463'
    assert_response :redirect
  end

  # Librarian View
  test "should render librarian view" do
    get '/catalog/bib_324680/librarian_view'
    assert_response :success
  end

  # Invalid bib id should return a 404
  test "404_for_invalid_bib" do
    assert_response 404 do
      get '/catalog/bib_4759863'
    end
  end
end
