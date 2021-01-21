module JournalTitleApplyLimit

  def self.included(klass)
    i = klass.default_processor_chain << :journal_title_apply_limit
  end

  # Journal Title field is selected, insert a facet limit for
  # just Journal, that's what it means. If we change
  # the value from "Journal/Newspaper", we'd have to change
  # below too.
  def journal_title_apply_limit(solr_params)

    if blacklight_params["search_field"] == "journal"
      solr_params[:fq] ||= []
      solr_params[:fq] << "{!raw f=format}Journal/Newspaper"
    end

    return solr_params
  end

end
