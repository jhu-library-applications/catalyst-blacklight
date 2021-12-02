require 'test_helper'

# HathiController test
class HathiControllerTest < ActionController::TestCase  
  def setup
    hathi_stub
  end   

  test "get an error if there is no session" do
    get 'index', params: { oclcnum: '1'}

    assert_response :forbidden
  end

  test "get no error there is a session" do
    session[:session_id] = 1
    get 'index', params: { oclcnum: '1'}
    
    json_response = JSON.parse(response.body)
    assert_not_nil json_response['records']
  end

end
