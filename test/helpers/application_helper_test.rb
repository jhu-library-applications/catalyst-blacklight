require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  test 'that we can easily decode a URL' do
    assert_equal('http://proxy.library.jhu.edu/login?url=http://www.heinonline.org/HOL/Index?collection=journals&index=journals/afjincol', url_decode('http://proxy.library.jhu.edu/login?url=http://www.heinonline.org/HOL/Index?collection=journals&index=journals%2Fafjincol'))
  end
 
  def current_page?(arg)
    true
  end

  test 'application name' do
    assert_equal(application_name, "JH Libraries")
  end

  test 'bootstrap_pill_link_to helper' do
    pill_link = bootstrap_pill_link_to('Foo', search_catalog_path({q:'foo'}), {class:'foo'})

    assert_match /nav-link active/, pill_link
  end

  test 'render_search_button helper' do
    search_button = render_search_button(
      "Catalog+Articles",
      :multi_search,
      search_url_context(
        :controller => "multi_search",
        :action => "index"
      )
    )

    assert_match /search-option btn active btn-primary/, search_button
  end


  test 'should_include_findit_url helper' do
    should_not_include = should_include_findit_url?(document: { 'format' => ['Map/Globe', 'Print'] })
    should_include = should_include_findit_url?(document: { 'format' => ['Book', 'Print'] })
    
    assert_equal should_not_include, false
    assert_equal should_include, true
  end
end
