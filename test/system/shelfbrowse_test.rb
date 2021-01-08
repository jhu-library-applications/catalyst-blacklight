require "application_system_test_case"

class ShelfbrowseTest < ApplicationSystemTestCase
  def test_shelfbrowse
    skip('@TODO - Javascript')
    visit '/catalog/bib_979538'
    assert page.has_content?("Virtual Shelf Browse")
    assert page.click_link("Browse")

    sleep(5)

    assert page.has_content?("Virtual Shelf Browse")
    assert page.has_selector?("h5.index_title")
    within("h5.index_title") do
      assert page.has_link?("1X1: [Poems]")
    end
  end
end
