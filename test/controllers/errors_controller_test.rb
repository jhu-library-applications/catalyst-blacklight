require 'test_helper'

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "bad bib id should return not_found" do
    get '/catalog/bib_3437683_fail'
    assert_response 404
  end

  test "should get not_found" do
    get '/404'
    assert_response :success
  end

  test "should get internal_server_error" do
    get '/500'
    assert_response :success
  end
end
