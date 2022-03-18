require "application_system_test_case"

class AdvancedSearchPageTest < ApplicationSystemTestCase

  def setup
    sfx_stub
    
    visit "/advanced"
  end

  def test_basic_dom
    assert page.has_content?("Advanced Search")
    assert page.has_content?("Field search")
    assert page.has_content?("Limit results by")
    assert page.has_content?("Clear form")
    assert page.has_content?("Search tips")
    within("div.limit-criteria") do
      assert page.has_content?("Format")
      assert page.has_content?("Item Location")
      assert page.has_content?("Language")
      assert page.has_content?("Musical Instrumentation")
      assert page.has_content?("Publication Year")
      assert page.has_no_content?("Organization")
    end
    within('.query-criteria') do
      assert page.has_selector?("input#unstemmed_search")
    end
    within('#query-criteria-buttons') do
      assert page.has_selector?("select#sort")
    end
  end

  def test_fielded_search
    # Form
    within('form.advanced') do
      fill_in('title', with: 'atlas')
      first('input[type="submit"]').click
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
      first('input[type="submit"]').click
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
      first('input[type="submit"]').click
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

  def test_has_remove_selections_button
    skip "Check blacklight bootstrap js"
    visit "/advanced"

    # Form
    within('form.advanced') do
      fill_in 'all_fields', with: 'records'
      first('input[type="submit"]').click
    end

    click_on('At the Library')

    # Results
    assert page.has_selector?('span[title="records"]')
    assert page.has_selector?('span[title="At the Library"]')
    assert page.has_link?("Start Over")
  end
end
