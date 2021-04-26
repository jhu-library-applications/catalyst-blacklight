require 'test_helper'

# This is for testing CQL functionality
# on the production server.

# If this test fails then FindIt will be unable
# to query Catalyst for holdings information.
class CqlLiveTest < ActionView::TestCase
  CATALYST_CQL_ATOM_URL =
    "https://catalyst.library.jhu.edu/catalog.atom?content_format=marc\
          &q=title+%3D+%22%5C%22The+double+elephant+folio%5C%22%22+\
            AND+author+%3D+%22Fries%2C+Waldemar+H+1889%22\
            &search_field=cql".freeze

  def setup
    WebMock.allow_net_connect!

    @document = URI.parse(CATALYST_CQL_ATOM_URL)
  end

  # If the response is returning a bib number then it
  # is working correctly.
  test 'receiving a response with a bib number' do
    assert(@document.read.include?('bib_616989'))
  end
end
