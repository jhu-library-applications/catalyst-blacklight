require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  def test_basic_dom
    visit '/articles'
    assert page.has_selector?(".search-navbar")
    within(".search-navbar") do
      assert page.has_link?("Catalog")
      assert page.has_text?("Articles")
    end

    assert page.has_selector?("#articles-instructions")
    assert page.has_text?("Search for scholarly articles using Google Scholar or a database. Databases require JHED login.")

    assert page.has_selector?("div.form-selector")
    assert page.has_selector?("#article-form-selector")
    assert page.has_link?("EBSCO databases", visible: false)
    assert page.has_link?("Google Scholar", visible: false)
    assert page.has_link?("JSTOR database", visible: false)
    assert page.has_link?("ProQuest databases", visible: false)
    assert page.has_link?("PubMed database", visible: false)

    assert page.has_selector?("div#article-forms")
    within("div#article-forms") do
      assert page.has_selector?("#af-basic")
      assert page.has_selector?("#af-google", visible: false)
      assert page.has_selector?("#af-jstor", visible: false)
      assert page.has_selector?("#af-pubmed", visible: false)
      assert page.has_selector?("#af-proq", visible: false)
    end

    assert page.has_text?("Need something more specialized?")
    assert page.has_link?("Search in a subject-specific database")
  end

  def test_jstor_dest_url
    visit '/articles'

    click_button 'EBSCO databases'
    sleep(1)

    within('.form-selector .dropdown-menu') do
      click_link 'JSTOR database'
    end

    # Form
    within('#af-jstor form') do
      fill_in('Query', with: 'Example Search')

      # Toggle online checkbox
      click_button 'Search'

      assert page.has_selector?("input[value='https://www.jstor.org/action/doBasicSearch?Query=Example Search']", visible:false)
    end
  end

end
