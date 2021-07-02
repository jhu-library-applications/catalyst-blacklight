require 'test_helper'

class MarcUrlPresenterTest < ActiveSupport::TestCase
  def setup
    WebMock.allow_net_connect!

    @document = SolrDocument.find('bib_1929587')
    @link = "<a href='http://proxy1.library.jhu.edu/login?url=http://aspace.library.jhu.edu/repositories/3/resources/898  '>aspace.library.jhu.edu</a>"
  end

  test 'we can get a formatted link' do
    assert_equal MarcUrlPresenter.new(@document).link, @link
  end
end
