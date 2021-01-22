require "application_system_test_case"

class AdvancedSearchPageTest < ApplicationSystemTestCase

  def setup
    visit "/advanced"
  end

  def test_basic_dom
    assert page.has_content?("Advanced Search")
    assert page.has_content?("Field search")
    assert page.has_content?("Other attributes")
    assert page.has_content?("Start over")
    assert page.has_content?("Search tips")
    within("div.limit-criteria") do
      assert page.has_content?("Format")
      assert page.has_content?("Item Location")
      assert page.has_content?("Language")
      assert page.has_content?("Musical Instrumentation")
      assert page.has_content?("Publication Year")
      assert page.has_no_content?("Organization")
    end
    within('div.sort-submit-buttons') do
      assert page.has_selector?("input#unstemmed_search")
      assert page.has_selector?("select#sort")
    end
  end

  def test_fielded_search
    # Form
    within('form.advanced') do
      fill_in('title', with: 'atlas')
      click_button 'Search'
    end

    # Results
    assert page.has_selector?("article.document")
    assert page.has_content?("Blumgart's video atlas : liver, biliary & pancreatic surgery")
  end

  def test_unstemmed_search
    # Form - Stemmed
    within('form.advanced') do
      fill_in 'all_fields', with: 'records'
      uncheck 'unstemmed_search'
      click_button 'Search'
    end

    # Results
    assert page.has_selector?("article.document")
    assert page.has_link?("Records")
    assert page.has_link?("The inventor")

    visit "/advanced"

    # Form - Unstemmed
    within('form.advanced') do
      fill_in 'all_fields', with: 'records'
      check 'unstemmed_search'
      click_button 'Search'
    end

    # Results
    assert page.has_selector?("article.document")
    assert page.has_link?("Records")
    assert page.has_no_link?("The inventor")

    # Constraint is rendered
    within('#appliedParams') do
      assert page.has_text?("Stemming disabled")
    end
  end
end
