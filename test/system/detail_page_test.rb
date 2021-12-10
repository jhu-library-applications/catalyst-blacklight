require "application_system_test_case"

class DetailPageTest < ApplicationSystemTestCase
  def test_basic_dom
    # Online Book
    visit '/catalog/bib_8435478'
    sleep(2)
    assert page.has_selector?("main#main-container")
    assert page.has_selector?("section.show-document")
    assert page.has_selector?("div#doc_bib_8435478")
    assert page.has_selector?("div.cover-container")
    assert page.has_selector?("span.show-marc-types")
    assert page.has_selector?("span.show-marc-languages")
    assert page.has_selector?("h1.show-marc-heading-title")
    assert page.has_selector?("span.show-marc-subtitle")
    assert page.has_selector?("span.stmt-resp")
    assert page.has_selector?("span.stmt-resp")
    assert page.has_selector?("div.links")
    assert page.has_selector?("div.umlaut")
    # assert page.has_selector?("ul.holdings")
    assert page.has_selector?("dl.dl-marc-display")
    assert page.has_selector?('.unapi-id', visible: false)
    assert page.has_selector?("section.page-sidebar")
    assert page.has_selector?("div.show-tools")
    assert page.has_selector?("li.bookmark")
    assert page.has_selector?("li.citation")
    assert page.has_selector?("li.refworks")
    assert page.has_selector?("li.endnote")
    assert page.has_selector?("li.email")
    assert page.has_selector?("li.librarian_view")
    assert page.has_selector?("div.footer")
  end

  def test_tools_cite
    # Check for action presense
    visit '/catalog/bib_8435478/'
    assert page.has_link?("Cite")

    # Check modal for citations
    click_link "Cite"
    assert page.has_selector?("#blacklight-modal.modal.show")
    within("#blacklight-modal.modal.show") do
      assert page.has_text?("MLA")
      assert page.has_text?("APA")
      assert page.has_text?("Chicago")
    end

    # Check full route is present
    visit '/catalog/bib_8435478/citation'
    assert page.has_content?("Cite")
  end

  def test_umlaut_includes
    visit '/catalog/bib_8039975'
    sleep(4) # Let Umlaut run

    # Excerpts
    assert page.has_selector?(".umlaut.excerpts")

    # Search inside
    assert page.has_selector?(".umlaut.search_inside")
  end

  def test_tools_email
    # Check for action presense
    visit '/catalog/bib_8435478/'
    assert page.has_link?("Email")

    click_link "Email"

    sleep(3)
    assert page.has_text?("Login")

    # Rack Session
    login_as(:john)
    visit '/catalog/bib_8435478/'

    # Check modal for email form
    click_link "Email"
    sleep(2)
    assert page.has_selector?("#blacklight-modal.modal.show")
    within("#blacklight-modal.modal.show") do
      assert page.has_text?("Email")
    end

    # Check full route is present
    visit '/catalog/bib_8435478/email'
    assert page.has_content?("Email")
  end

  def test_tools_librarian_view
    # Check for action presense
    visit '/catalog/bib_8435478/'
    assert page.has_link?("Librarian View")

    # Check modal for no-layout
    click_link "Librarian View"
    assert page.has_selector?("#blacklight-modal.modal.show")
    within("#blacklight-modal.modal.show") do
      assert page.has_no_text?("Catalyst")
    end

    # Check full route is present
    visit '/catalog/bib_8435478/librarian_view'
    assert page.has_content?("Librarian View")
  end
end
