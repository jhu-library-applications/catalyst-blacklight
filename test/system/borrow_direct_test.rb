# coding: utf-8
require "application_system_test_case"

class BorrowDirectTest < ApplicationSystemTestCase
  def setup
    relais_request_unavailable_stub
  end

  # Scenario: For checking BD for online book and returning unavailable
  def test_bd_borrowing
    visit '/catalog/bib_8435478'
    sleep(2)
    assert page.has_content?("Check BorrowDirect")
    assert page.has_content?("Request via Interlibrary Loan")
  end

end
