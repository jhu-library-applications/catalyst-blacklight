# MultiSearch
#
# Default params: facet should be false and return only 5 results
module MultiSearchSolrParamsLogic
  def self.included(klass)
    klass.default_processor_chain += [:multi_search_solr_params]
  end

  def multi_search_solr_params(solr_params)
    if (
      blacklight_params[:controller] == 'multi_search' && blacklight_params[:action] == 'index'
      )

      solr_params[:facet] = "false"
      solr_params[:rows] = "5"
    end
    return solr_params
  end

end
