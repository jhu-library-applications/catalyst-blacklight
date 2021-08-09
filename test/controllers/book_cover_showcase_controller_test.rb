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

  test "should render bookcover image from isbn" do
    get '/bookcover?isbn=020588699X,9780205886999,0205933491,9780205933495,0205949525,9780205949526&format=Book,Print'
    assert_response :redirect
  end

  test "should render bookcover image from bib" do
    get '/bookcover?bib=bib_8334977'
    assert_response :redirect
  end
end