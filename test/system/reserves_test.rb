require "application_system_test_case"

class ReservesTest < ApplicationSystemTestCase

  def setup
    Flipper[:curbside_mode].disable
    visit "/reserves"
  end

  def test_basic_dom
    assert page.has_selector?('form.reserves-search')
    assert page.has_selector?('input#q')
    assert page.has_selector?('div.reserves-location-limits')
    assert page.has_selector?('span.page-entries')
    assert page.has_selector?('div.course')
    assert page.has_selector?('div.pagination')
  end

  def test_search
    # Form
    within('form.reserves-search') do
      fill_in('q', with: 'Warnock')
      click_button 'Find'
    end

    # Results
    assert page.has_selector?("div.course")
    assert page.has_content?("010.102, Spring 2020")
  end

  def test_course_view
    visit "/reserves/20242"
    assert page.has_selector?("div.reserves-show-course-header")
    assert page.has_content?("010.102, Spring 2020")
    assert page.has_selector?("div#documents")
    assert page.has_selector?("article.document")
  end
end
