require 'test_helper'

# UsersController - Testing public methods and response formats
class UsersControllerTest < ActionDispatch::IntegrationTest
  # No session - redirect to login
  test "no session - should redirect user" do
    get '/user'
    assert_response :redirect
  end

  test "session - should render user page" do
    skip "Horizon Unavailable" if horizon_unavailable?
    sign_in
    get '/user'
    assert_response :success
  end

  test "session - should render user requests" do
    skip "Horizon Unavailable" if horizon_unavailable?
    sign_in
    get '/user/requests'
    assert_response :success
  end

  test "session - should render user profile" do
    skip "Horizon Unavailable" if horizon_unavailable?
    sign_in
    get '/user/profile'
    assert_response :success
  end

  test "new" do
    assert_raises ActionController::RoutingError do
      get '/user/new'
    end
  end

  test "create" do
    assert_raises ActionController::RoutingError do
      post '/user/create'
    end
  end

  test "itemsout" do
    sign_in
    get '/user/itemsout'
    assert_response :redirect
  end
end
