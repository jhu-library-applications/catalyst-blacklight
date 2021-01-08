# Add on to CatalogController or another SolrHelper
#, to support :unstem_search param to search only un-stemmed fields. 

module UnstemSolrParams
  
  def self.included(klass)
    i = klass.default_processor_chain << :add_unstemmed_overrides_to_solr    
  end
  
    ##
    # If unstemmed_search is selected, then we add params to redefine
    # things like $author_qf, $title_qf, etc.. Normally those are supplied
    # by Solr solrconfig.xml defaults, but we define em explicitly in the
    # request to contain only unstemmed fields. 
    def add_unstemmed_overrides_to_solr(solr_parameters)
      
      if blacklight_params[:unstemmed_search]
        blacklight_config.unstemmed_overrides.each_pair do |key, value|
          solr_parameters[key] = value
        end        
      end            
      
      return solr_parameters
    end
  
end
