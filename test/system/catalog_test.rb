# coding: utf-8
require "application_system_test_case"

class CatalogTest < ApplicationSystemTestCase
  def setup
    holdings_stub
    sfx_stub
  end

  def test_search
    visit '/catalog?q=film'
    assert page.has_content?("Refine your search")
  end

  # HELP-18811
  # Scenario: Citation should include imprint data from MARC 264 field in the absence of 260 field
  def test_marc_264_citation_copy
    visit '/catalog/bib_4839582'
    click_link 'Cite'
    assert page.has_content?("Boydell Press")
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
    visit '/catalog/bib_305929'
    assert page.has_content?("Friedheim -- Main stacks")
    assert page.has_link?('Get It')
  end

  # Scenario: For online access items, it shows the link to the item
  def test_online_access
    visit '/catalog/bib_8279815'
    assert page.has_content?("Academic Search Ultimate")
  end

  # LAG-1242
  # This is for testing that the finding aid link shows up. Remove it after moving those
  # records out of horizon
  # Other links from findit should still appear
  # Scenario: An archive special collection should keep the online access link
  def test_finding_aid_link
    visit '/catalog/bib_407427'
    assert page.has_content?("jscholarship")
  end

  # LAG-1242 Testing borrow direct box for archives items.
  # Scenario: An archives special collection record should not display the borrow direct box
  def test_borrow_direct_box
    visit '/catalog/bib_1929587'
    assert page.has_no_content?("Request from another library")
  end

  # LAG-1242
  # Remove redundant finding aid links if both catalyst and findit renders it
  # Scenario: An archives special collection record should display only one finding aid link
  def test_borrow_direct_box
    visit '/catalog/bib_3958668'
    sleep(2)
    assert page.has_content?("aspace.library.jhu.edu")
  end

  # HELP-20072
  # Scenario: Related titles should return consistent results: example 1
  def test_related_titles_results_1
    visit '/catalog/bib_3850534'
    click_link("Bach, Johann Sebastian, 1685-1750. Concertos, harpsichords (2), BWV 1061a, C major.")
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
    visit '/catalog/bib_305929'
    within('div.holdings-drill-down', match: :first) do
      first('a.request').click
    end 
    assert page.has_no_content?('Network Error')
    assert page.has_content?('Login')
  end

  # Test txt Button - Not signed in
  def test_sms_button_auth_redirect
    visit '/catalog/bib_8039975/sms/9369463'
    assert page.has_no_content?('Network Error')
    assert page.has_content?('Login')
  end

  # LAG-4185
  # Make sure we are giving a 404 page for a failed cql request and not a 500
  def test_cql_error_page
    visit '/catalog?utf8=✓&search_field=cql&q=title+%3D+%22%5C%22People+and+Nature%5C%22%22+test&content_format=marc&f%5Bformat%5D%5B%5D=Journal%2FNewspaper&format=html'
    assert page.has_no_content? 'Internal Server Error'
    assert page.has_content? 'Page Not Found'
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

  # Test result set show page pagination
  def test_show_page_result_set_pagination
    visit '/catalog?q=piano'
    sleep(2)
    click_on('At the Library')

    # Results
    assert page.has_no_selector?('span[title="piano"]')
    assert page.has_selector?('span[title="At the Library"]')
    assert page.has_link?("Remove Selections")
  end
end
