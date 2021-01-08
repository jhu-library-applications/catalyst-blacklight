require 'test_helper'

# CatalogController - Testing public methods and response formats
class BookmarksControllerTest < ActionDispatch::IntegrationTest
  test "should render bookmarks homepage" do
    get '/bookmarks'
    assert_response :success
  end
end
