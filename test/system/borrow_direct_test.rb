# coding: utf-8
require "application_system_test_case"

class BorrowDirectTest < ApplicationSystemTestCase


  # Scenario: For checking BD for online book and returning unavailable
  def test_bd_borrowing_button
    relais_request_unavailable_stub

    visit '/catalog/bib_8435478'
    sleep(1)
    assert page.has_content?("Check BorrowDirect")
    assert page.has_content?("Request via Interlibrary Loan")
  end

  # Scenario: For checking BD for online book and returning unavailable
  def test_bd_borrowing_form
    relais_request_available_stub

    visit '/catalog/bib_8435478'
    sleep(1)
    assert page.has_content?("Please choose a delivery location")
  end

end
