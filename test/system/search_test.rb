# coding: utf-8
require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  def test_having_a_label_for_any_field_search
    visit '/'
    fill_in 'Q', with: 'test'
    click_on 'Search'
    assert page.has_content?('Any Field')
  end

  def test_having_unapi_element
    visit '/catalog?utf8=✓&search_field=all_fields&q=*'

    assert page.has_selector?('.unapi-id', visible: false)
  end
end
