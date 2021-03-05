# coding: utf-8
require "application_system_test_case"

class AdvancedSearchLinkTest < ApplicationSystemTestCase
  def test_advanced_search_link_from_bib_show
    visit '/catalog/bib_4839582'
    click_on 'Advanced Search'

    assert_equal page.current_path, '/advanced'
    refute_match /search_field/, page.current_url
  end

  def test_advanced_search_link_from_advanced_search
    visit '/advanced'
    fill_in 'Any Field', with: 'testing-the-search'
    click_on 'Search'
    click_on 'Advanced Search'

    assert page.has_xpath?("//input[@value='testing-the-search']")
  end

  def test_advanced_search_link_from_search
    visit '/'
    fill_in 'Q', with: 'testing-the-search'
    click_on 'Search'
    click_on 'Advanced Search'

    assert page.has_xpath?("//input[@value='testing-the-search']")
  end
end
