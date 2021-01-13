require "application_system_test_case"

class FloormapTest < ApplicationSystemTestCase
  def test_full_page_floormap
    visit '/floormap?call_number=BS580.B3+R63+2019&collection_code=emain'
    assert page.has_content?("Item Floor Map")
    assert page.has_content?("BS580.B3 R63 2019")
    assert page.has_selector?('img.stackmap')
  end
end
