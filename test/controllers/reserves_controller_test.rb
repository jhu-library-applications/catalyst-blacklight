require 'test_helper'

# ReservesController - Testing public methods and response formats
class ReservesControllerTest < ActionDispatch::IntegrationTest
  test "should render reserves homepage" do
    get '/reserves'
    assert_response :success
  end

  test "should render reserve show page" do
    # @TODO: Not finding docs, mv to BL7 fetch_all for bib_ids
    # Should look pretty similar to BookmarksController multiple id calls
    get '/reserves/20242'
    assert_response :success
  end
end
