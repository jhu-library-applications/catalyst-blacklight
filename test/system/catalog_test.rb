# coding: utf-8
require "application_system_test_case"

class CatalogTest < ApplicationSystemTestCase
  def test_search
    visit '/catalog?q=film'
    assert page.has_content?("Refine your search")
    assert page.has_content?("You searched for")
    assert page.has_link?("Start Over")
  end

  def test_search_online_only
    visit '/catalog'

    # Form
    within('form.catalog-search') do
      search_field = page.find("#search_field", visible: false).value
      assert_equal("all_fields", search_field)

      fill_in('q', with: 'book')

      # Toggle online checkbox
      check 'online_only'
      click_button 'Search'
    end

    # Results present
    assert page.has_selector?("article.document")

    # Online faceted
    assert page.has_selector?("span.facet-label > span.selected")
    selected = page.find("span.facet-label > span.selected").text
    assert_equal("Online", selected)
  end

  # HELP-18811
  # Scenario: Citation should include imprint data from MARC 264 field in the absence of 260 field
  def test_marc_264_citation_copy
    visit '/catalog/bib_4839582'
    click_link 'Cite'
    assert page.has_content?("Woodbridge, Suffolk, UK: The Boydell Press")
  end

  # Scenario: Display metadata in MARC 351 field
  def test_marc_351_copy
    visit '/catalog/bib_6627346'
    assert page.has_content?("Organized into 13 series")
  end

  # Scenario: Display metadata in MARC 541$d
  def test_marc_541d_copy
    visit '/catalog/bib_6626889'
    assert page.has_content?("Wilda Heiss; 2012")
  end

  # Scenario: Display metadata in MARC 555
  def test_marc_555_copy
    visit '/catalog/bib_6626889'
    assert page.has_content?("http://aspace.library.jhu.edu/repositories/4/resources/1159")
  end

  # Scenario: Display 555$u as a clickable link
  def test_marc_555u_link
    visit '/catalog/bib_6626889'
    assert page.has_content?("http://aspace.library.jhu.edu/repositories/4/resources/1159")
    assert page.has_link?("http://aspace.library.jhu.edu/repositories/4/resources/1159")
  end

  # Scenario: Copy holdings should not show "txt" button
  def test_copy_holdings
    skip "Horizon Unavailable" if horizon_unavailable?
    visit '/catalog/bib_305929'
    page.find('li.holding', match: :first).click # Multiple Items
    click_link('Items')
    assert page.has_content?("Friedheim -- Main stacks")
    assert page.has_link?('Request')
  end

  # Scenario: For non-online access items, it shows "Not Available"
  def test_non_online_access
    visit '/catalog/bib_305929'
    sleep(6)
    within('div.links') do
      assert page.has_content?("Not Available")
    end
  end

  # Scenario: For online access items, it shows the link to the item
  def test_online_access
    visit '/catalog/bib_8435478'
    assert page.has_content?("www.clinicalkey.com")
  end

  # LAG-1242
  # This is for testing that the finding aid link shows up. Remove it after moving those
  # records out of horizon
  # Other links from findit should still appear
  # Scenario: An archive special collection should keep the online access link
  def test_finding_aid_link
    visit '/catalog/bib_407427'
    assert page.has_content?("jscholarship.library.jhu.edu")

    # JS switches label from 'Finding aid:' to 'Collection guide available:'
    sleep(2)
    assert page.has_content?("Collection guide available: http://aspace.library.jhu.edu/repositories/3/resources/981")
  end

  # LAG-1242 Testing borrow direct box for archives items.
  # Scenario: An archives special collection record should not display the borrow direct box
  def test_borrow_direct_box
    visit '/catalog/bib_1929587'
    assert page.has_no_content?("Request a copy from BorrowDirect")
  end

  # LAG-1242
  # Replace label with "Collection guide available:"
  # Remove redundant finding aid links if both catalyst and findit renders it
  # Scenario: An archives special collection record should display only one finding aid link
  def test_borrow_direct_box
    visit '/catalog/bib_3958668'
    sleep(2)
    assert page.has_content?("Collection guide available:")
  end

  # HELP-20072
  # Scenario: Related titles should return consistent results: example 1
  def test_related_titles_results_1
    visit '/catalog/bib_3850534'
    click_link("Bach, Johann Sebastian, 1685-1750. Concertos, harpsichords (2), BWV 1061a, C major")
    assert page.has_selector?("article.document", count: 1)
  end

  # Scenario: Related titles should return consistent results: example 2
  def test_related_titles_results_2
    visit '/catalog/bib_324680'
    click_link("Schoenberg, Arnold, 1874-1951. Stücke, mixed voices, op. 27.")
    assert page.has_selector?("article.document", count: 1)
  end

  # Display show marc heading
  def test_show_marc_heading
    visit '/catalog/bib_324680'
    assert page.has_content?("Musical Recording , CD in German , English , Hebrew")
  end

  # Test Request Button - Not signed in
  def test_request_button_auth_redirect
    skip "Horizon Unavailable" if horizon_unavailable?
    visit '/catalog/bib_305929'
    first('div.holding-visible').click
    first('a.item-children-link').click
    first('a.request').click
    assert page.has_no_content?('Network Error')
    assert page.has_content?('Login')
  end

  # Test txt Button - Not signed in
  def test_sms_button_auth_redirect
    visit '/catalog/bib_8039975/sms/9369463'
    assert page.has_no_content?('Network Error')
    assert page.has_content?('Login')
  end

  # Test result set show page pagination
  def test_show_page_result_set_pagination
    visit '/catalog?q=piano'
    sleep(2)
    first('h3.index_title > a').click
    sleep(2)
    assert page.has_content?("Previous")
    assert page.has_link?("Next")
  end
end
