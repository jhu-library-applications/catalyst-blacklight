# coding: utf-8
require "application_system_test_case"

# This tests that the Blacklight CQL plugin
# is working as expected.

# Find It uses catalyst to look up ebook
# holdings. It does this by running a
# CQL search and getting the results in
# atom XML format.
class CqlTest < ApplicationSystemTestCase
  def test_that_cql_behaves_as_find_it_expects
    holdings_stub

    visit '/catalog.atom?search_field=cql&content_format=marc&q=title+%3D+"%5C"Organic+chemistry"'

    assert page.has_content? '/catalog/bib_2653739</id>'
  end
end
