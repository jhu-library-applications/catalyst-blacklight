class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  # Required by Find It / umlaut
  include BlacklightCql::SearchBuilderExtension

  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr]

  # Our custom local Solr filters to apply our custom local
  # search features.
  include JournalTitleApplyLimit
  include UnstemSolrParams
  include HomePageSolrParamsLogic
  include MultiSearchSolrParamsLogic

  # @TODO: Removing - EWL
  # blacklight_cql is no longer maintained
  # include BlacklightCql::SearchBuilderExtension

  # @TODO: Removing - EWL
  # self.default_processor_chain += [:add_facet_fq_to_solr]
  # if BlacklightAdvancedSearch is loaded
  # if defined? BlacklightAdvancedSearch
  #   self.default_processor_chain << :add_facet_fq_to_solr
  # end

  #self.default_processor_chain += %i[exclude_components filter_by_parent_collections]

end
