require "application_system_test_case"

class HomepageTest < ApplicationSystemTestCase
  def setup
    WebMock.allow_net_connect!

    visit("/")
  end

  def test_basic_dom
    assert page.has_selector?("nav")
    assert page.has_selector?("div#jhu-main-nav")
    assert page.has_selector?("div#jhu-app-nav")
    within("div#jhu-main-nav") do
      assert page.has_link?("Sheridan Libraries")
      assert page.has_link?("Welch Medical Library")
      assert page.has_link?("SAIS Library")
      assert page.has_link?("Arthur Friedheim Library")
      assert page.has_link?("APL Library")
    end
    within("ul.account-dropdown") do
      assert page.has_link?("Bookmarks")
      assert page.has_link?("Login")
    end
    within("div#jhu-app-nav") do
      assert page.has_selector?("img")
      assert page.has_link?("Catalyst")
      assert page.has_link?("Other Resources")
    end
    assert page.has_selector?("div.search-container")
    within("div.search-container") do
      assert page.has_selector?("div.search-navbar")
      within("div.search-navbar") do
        assert page.has_text?("Catalog")
        assert page.has_link?("Articles")
      end
      assert page.has_selector?("form.catalog-search")
      within("form.catalog-search") do
        assert page.has_selector?("input#search_field", visible: false)
        assert page.has_selector?("input#q")
        assert page.has_selector?("button#search")
      end
    end
  end

  def test_homepage_search
    within("form.catalog-search") do
      fill_in("q", with: 'film')
      click_button 'Search'
    end

    # Results
    assert page.has_selector?("article.document")
  end
end
