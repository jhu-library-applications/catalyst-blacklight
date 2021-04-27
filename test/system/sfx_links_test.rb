require 'application_system_test_case'

class SfxLinksSystemTest < ApplicationSystemTestCase
  def that_that_we_get_a_link_from_sfx
    visit '/catalog?f%5Bformat%5D%5B%5D=Journal%2FNewspaper&q=&search_field=all_fields'
    assert page.has_selector? '.external-resources-container'
    assert page.has_content? 'EBSCOhost'
  end
end
