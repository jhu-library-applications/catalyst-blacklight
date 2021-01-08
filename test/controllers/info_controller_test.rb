require 'test_helper'

# InfoController - Testing public methods and response formats
class InfoControllerTest < ActionDispatch::IntegrationTest
  test "should render useful_links page" do
    get '/info/useful_links'
    assert_response :success
  end

  test "should render unstemmed_desc page" do
    get '/info/unstemmed_desc'
    assert_response :success
  end

  test "should render research_links page" do
    get '/info/research_links'
    assert_response :success
  end

  test "should render libraries page" do
    get '/info/libraries'
    assert_response :success
  end

  test "should render credits page" do
    get '/info/credits'
    assert_response :success
  end
end
