# When on home page, we don't actually show any results,
# but BL does a Solr search anyway (for everything). It's hard to get BL
# to not do this, but we can at least make it do facets=false
# to make it a cheap search. 

module HomePageSolrParamsLogic
  def self.included(klass)
    klass.default_processor_chain += [:home_page_solr_params]
  end
  
  # for requests of type html, refuse to do a search for an empty query -- we want
  # the /catalog home page to just display the search box, not the first page
  # of results for everything in the catalog. 
  #
  # We'll allow empty string query to give all results, useful for debugging purposes,
  # just no params at all.
  def home_page_solr_params(solr_params)
    if ( blacklight_params[:format].blank? || blacklight_params[:format] == "html") && 
        blacklight_params[:controller] == 'catalog' && blacklight_params[:action] == 'index' &&
        !(blacklight_params[:q].present? || 
          blacklight_params[:f].present? || 
          blacklight_params[:search_field].present? ||
          blacklight_params[:range].present?
          )
        

      solr_params[:facet] = "false"
      solr_params[:stats] = "false"
      solr_params[:rows] = "0"
    end
    return solr_params    
  end  
  
end
