require 'test_helper'

class CqlHelperTest < ActionView::TestCase
  test 'that we can remove CQL formatting from a title CQL query' do
    actual_params = { content_format: 'marc', q: 'title = "\"Accounts of Chemical Research\""', search_field: 'cql', f: '[format][]=Journal/Newspaper' }
    ideal_params = { search_field: 'title', q: 'Accounts of Chemical Research', f: '[format][]=Journal/Newspaper' }

    assert_equal ideal_params, reformatted_cql_search(params: actual_params)
  end

  test 'that we can remove CQL formatting from an author CQL query' do
    actual_params = { content_format: 'marc', q: 'author = "\"J Smith\""', search_field: 'cql', f: '[format][]=Journal/Newspaper' }
    ideal_params = { search_field: 'author', q: 'J Smith', f: '[format][]=Journal/Newspaper' }

    assert_equal ideal_params, reformatted_cql_search(params: actual_params)
  end

  test 'that we can remove CQL formatting from a title & author CQL query' do
    actual_params = { content_format: 'marc', q: 'title = "\"Accounts of Chemical Research\"" AND author = "J Smith"', search_field: 'cql', f: '[format][]=Journal/Newspaper' }
    ideal_params = {  q: 'Accounts of Chemical Research J Smith', search_field: 'all_fields', f: '[format][]=Journal/Newspaper' }

    assert_equal ideal_params, reformatted_cql_search(params: actual_params)
  end
end
