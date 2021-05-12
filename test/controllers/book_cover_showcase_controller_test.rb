require 'test_helper'
class BookCoverShowcaseControllerTest < ActionDispatch::IntegrationTest
  def setup
    WebMock.allow_net_connect!
  end

  test "should render bookcovers json" do
    get '/bookcovershowcase.json?search_field=all_fields&q=*&per_page=1'
    json_response = JSON.parse(response.body)
    json_response.has_key?('bookcovers')
  end
end