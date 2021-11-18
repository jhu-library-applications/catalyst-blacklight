# encoding: UTF-8

require 'borrow_direct'
require 'marc'

module LocalCatalogHelper
  include Blacklight::CatalogHelperBehavior

  # Include helper methods from MarcDisplay plugin
  include MarcDisplayHelper

  # Called by Blacklight catalog/show, item detail page. We replace a simple heading
  # with a whole partial, for marc docs.
  def render_document_heading(*args)
    if ( document_to_marc(@document))
      render(:partial => "catalog/show_marc_heading", :locals => {:document => @document})
    else
      # BL plugin default
      super
    end
  end

  # Over-ride render_document partial to use our marc-display partial
  # for marc records in 'show' item detail.
  def render_document_partial(document, action_name, options = {})
    if ( action_name == :show && document_to_marc(document))
      render :partial => "catalog/show_marc", :locals => {:document => document}
    elsif (action_name == :index && document_to_marc(document))
      render :partial => "catalog/index_marc", :locals => {:document => document}
    else
      super
    end
  end

  # Over-ride of method from marc_display plugin to add in our EZProxy prefix.
  def link_out_to_856(value)
    # important we use "qurl" with an escaped URL for predictable
    # escaping semantics and legality. Before we tried unquoted &url=, and
    # it resulted in URLs with "&" in them being corrupted by Rails.
    "http://proxy.library.jhu.edu/login?qurl=#{CGI.escape value}"
  end

  # This was once an over-ride from BL, not it just might be our own method called
  # by our own code, not sure. We want to use value computed from MARC for title
  # on search results page, when we have marc. Also, support
  # a truncate option, :truncate => 100, 100 chars.
  # defaults to 200, set :truncate => nil to avoid.
  # @TODO - Remove?
  def document_heading(document, opts = {})
    truncate = opts.has_key?(:truncate) ? opts.delete(:truncate) : 160

    text= if document_to_marc(document)
      marc_index_title(document)
    else
      super
    end

    text = truncate(text, :omission => '…', :separator => ' ', :length => truncate) if truncate

    return text
  end

  # Function from Blacklight function that generates a linked doc title
  # to include in the search results list. We over-ride to use our own custom
  # HTML, that adds a span for an #anchor, and adds some additional display.
  def jhu_link_to_document(doc, label, opts)
    span_with_anchor = if opts && opts[:counter]
      content_tag("span", "", :id => "doc_counter_#{opts[:counter]}")
    else
      "".html_safe
    end

    # let's add in formats and languages
    suffix = content_tag("span", :class => "index-title-subhead") do
      content_tag("span", heading_type_str(doc), :class => "types") +
      if (languages = heading_language_str(doc))
        " in ".html_safe + content_tag("span", languages, :class => "languages")
      else
        ""
      end
    end

    link = link_to label, url_for_document(doc), document_link_params(doc, opts)

    return  safe_join([span_with_anchor, link_to_document(doc, label, opts), suffix], " ")

  end

  # Returns :online (fulltext) or :related, based on our
  # guess of whether the 856 links are for online access or not -- just
  # based on whether it's marked "Online" in format facet, at present.
  def related_links_type(document)
    if document["format"] && document["format"].include?("Online")
      :online
    else
      :related
    end
  end

  def hathi_eta(document)
    access = parse_csv(document, 'hathi_access')
    if (access[0]== "deny" || access[0] == "allow") && access[1].in?(['pd-pvt', 'nobody']) == false
      true
    else
      false
    end
  end

  def hathi_eta_only(document)
    access = parse_csv(document, 'hathi_access')
    if access[0] == "deny" && access[1].in?(['pd-pvt', 'nobody']) == false
      true
    else
      false
    end
  end

  def parse_csv(document, type)
    if document[type] != "" && document[type] != nil
      tempString = document[type]
      tempString = tempString.tr("[", "")
      tempString = tempString.tr("]", "")
      tempString = tempString.tr("'", "")
      tempArray = tempString.split(',')
      return tempArray
    else
      return []
    end
  end

  def related_hathi_links_etas_only(document)
    access = parse_csv(document, 'hathi_access')
    if access[0] == "deny"  && access[1].in?(['pd-pvt', 'nobody']) == false
      urls = parse_csv(document, "hathi_url")
      return process_urls(urls)
    else
      return []
    end
  end

  def related_hathi_links(document)
    access = parse_csv(document, 'hathi_access')
    if (access[0] == "deny" || access[0] == "allow")  && access[1].in?(['pd-pvt', 'nobody']) == false
      urls = parse_csv(document, "hathi_url")
      return process_urls(urls)
    else
      return []
    end
  end

  def process_urls(urls)
    urls.map! { |url|
      url = 'https://babel.hathitrust.org/Shibboleth.sso/Login?entityID=urn:mace:incommon:johnshopkins.edu&target=https://babel.hathitrust.org/cgi/ping/pong?target='+url
    }
    return urls
  end

  def related_links_title(document)
    if related_links_type(document) == :online
      "Online Access"
    else
      "Related Links"
    end
  end

  # returns css classes as space-separated string
  def holding_status_classes(holding)
    classes = []


    if holding && holding.status && holding.status.dlf_expanded_code
      classes << ("dlf-"+ holding.status.dlf_expanded_code.parameterize)
    end

    if holding && holding.status && holding.status.display_label && holding.status.display_label.upcase == "AVAILABLE"
      classes << "available"
    end

    return classes.join(" ")
  end

  # Is it appropriate to show a borrow direct link for this bib? Based on local
  # holdings availability.
  #
  # some of this logic duplicates logic in our Umlaut/Find It config for what
  # we consider locally available. We don't want to rely on Find It JS api here,
  # because we can get some stuff right on the page sooner without it. Sorry for
  # duplication.
  def show_borrow_direct?(document)
    # If this item does NOT appear to be a 'journal' type thing -- we
    # use openurl for this to try stay close to how Umlaut is deciding.
    #
    # AND
    #
    # If there's at least one holding that is Available or from archives special collections* (See LAG-1242)
    # and does NOT have collection containing Reserve(s) or "non-circulating",  then it's
    # locally available for BD purposes.
    #
    # * This should be removed after migrating archival collections out of horizon
    #
    # BUT
    # Multiple-item copies (has_children?) do not trigger BD for now.

    return  document.respond_to?(:to_openurl) &&
            document.to_openurl.referent.format != "journal" &&
            document.respond_to?(:to_holdings) &&
            ! document.to_holdings.find {|h|
                (h.has_children? || h.status.try(:display_label) == "Available" ||
                    %w(ecageki eofart eofms esmanu esgpms esarck esarc).include?(h.collection.try(:internal_code))
                ) &&
                 h.collection.try(:display_label) !~ /(reserves?)|(non-circulating)/i
            }
  end

  # Shelf browse is available if we have a record in our table indexing call numbers.
  # Returns either nil if no sort key is available, or a sort key if one is.
  # If multiple ones are available, it's more or less arbitrary which gets returned.
  def shelf_browse_sort_key_for(document)
    StackviewCallNumber.where(:system_id => document.id).order("created_at").pluck(:sort_key).first
  end


  # Generate a search link to BorrowDirect -- duplicates some
  # functionality in Umlaut/Findit umlaut_borrow_direct, but we
  # want to generate links immediately without waiting for slow
  # Find It AJAX, and in some places where we don't currently
  # have access to Find It AJAX. We'll try to keep the link
  # consistent by using shared borrow_direct gem functionality.
  #
  # returns nil if we can't generate a link.
  def borrow_direct_search_url(document)
    # We use the OpenURL conversion to get author and title out,
    # to stay consistent with Find It/Umlaut, and because it's
    # convenient.
    if document.respond_to?(:to_openurl) && (openurl = document.to_openurl)
      ou_metadata = openurl.referent.metadata

      author = ou_metadata["aulast"] || ou_metadata["au"]
      title  = ou_metadata["btitle"] || ou_metadata["title"]

      return BorrowDirect::GenerateQuery.new( borrow_direct_url ).
        normalized_author_title_query(
          :title  => title,
          :author => author
        )
    end
  end

  def link_to_borrow_direct_search(document)
    link_to "Check BorrowDirect", borrow_direct_search_url(document), :class => "btn btn-primary btn-sm", :target => "_blank"
  end

  def link_to_borrow_direct_from_search(params)
    query = Hash.new
    if params.has_key?(:search_field) and params[:search_field] == 'title'
      query[:title] = params[:q]
    end
    if params.has_key?(:search_field) and params[:search_field] == 'author'
      query[:author] = params[:q]
    end
    if params.has_key?(:search_field) and params[:search_field] == 'all_fields'
      query[:keyword] = params[:q]
    end
    if params.has_key?(:search_field) and params[:search_field] == 'subject'
      query[:keyword] = params[:q]
    end
    if params.has_key?(:search_field) and params[:search_field] == 'advanced'
      query[:keyword] = params[:all_fields]
      query[:author] = params[:author]
      query[:title] = params[:title]
    end
    url = BorrowDirect::GenerateQuery.new( borrow_direct_url ).query_url_with(query)

    link_to "Check BorrowDirect", url, :class => "btn btn-primary btn-sm", :target => "_blank"
  end

  # HELP-18811 Citation missing imprint from marc 264 field
  # Patch the marc so that if 260 is empty and 264 is present, the field in 264 would be copied to 260
  # Must return a SolrDocument for citation method calls
  def update_marc_for_citation(document)
    marc = document['marc_display']
    record = MARC::Reader.decode marc
    if not record['260'] and record['264']
      record['264'].tag = '260'

    end
    # BL7 Fix
    # DEPRECATION WARNING: Blacklight::Document#[]= is deprecated; use obj.to_h.[]= instead.
    hashed_document = document.to_h
    hashed_document['marc_display'] = record.to_marc
    SolrDocument.new(hashed_document)
  end

  # Override BL - EWL
  # BentoSearch::Results::Pagination does not have a size method.
  # Blacklight expects a size method, which is an alias of total_count.
  #
  # @TODO: add size method to BentoSearch::Results::Pagination
  ##
  # Override the Kaminari page_entries_info helper with our own, blacklight-aware
  # implementation. Why do we have to do this?
  #  - We need custom counting information for grouped results
  #  - We need to provide number_with_delimiter strings to i18n keys
  # If we didn't have to do either one of these, we could get away with removing
  # this entirely.
  #
  # @param [RSolr::Resource] collection (or other Kaminari-compatible objects)
  # @return [String]
  def page_entries_info(collection, entry_name: nil)
    entry_name = if entry_name
                   entry_name.pluralize(collection.size, I18n.locale)
                 else
                   if collection.respond_to?(:size)
                     collection.entry_name(count: collection.size).to_s.downcase
                   else
                     "Pages"
                   end
                 end

    entry_name = entry_name.pluralize unless collection.total_count == 1

    # grouped response objects need special handling
    end_num = if collection.respond_to?(:groups) && render_grouped_response?(collection)
                collection.groups.length
              else
                collection.limit_value
              end

    end_num = if collection.offset_value + end_num <= collection.total_count
                collection.offset_value + end_num
              else
                collection.total_count
              end

    case collection.total_count
      when 0
        t('blacklight.search.pagination_info.no_items_found', entry_name: entry_name).html_safe
      when 1
        t('blacklight.search.pagination_info.single_item_found', entry_name: entry_name).html_safe
      else
        t('blacklight.search.pagination_info.pages', entry_name: entry_name,
                                                     current_page: collection.current_page,
                                                     num_pages: collection.total_pages,
                                                     start_num: number_with_delimiter(collection.offset_value + 1),
                                                     end_num: number_with_delimiter(end_num),
                                                     total_num: number_with_delimiter(collection.total_count),
                                                     count: collection.total_pages).html_safe
    end
  end

  def show_borrow_direct_suggestion(params)
    ['all_fields', 'author', 'title', 'subject'].include?(params[:search_field])
  end

  def show_article_search_suggestion(params)
    ['all_fields', 'author', 'title', 'journal', 'subject'].include?(params[:search_field])
  end

  def book_cover(isbns)
    cover_image = nil
    if isbns.respond_to?('each')
      isbns.each do |isbn|
        response = Faraday.get 'https://www.googleapis.com/books/v1/volumes?key='+ ENV['GOOGLE_BOOKS_API_KEY'] +'&fields=items(volumeInfo(imageLinks))&q=isbn:' + isbn
        cover = MultiJson.load(response.body)
        if cover['items']
          cover_image = cover['items'][0]['volumeInfo']['imageLinks']['smallThumbnail']
        end
        break if cover_image
      end
      cover_image
    end
  end

  def cover_formats(document)
    formats = ''
    if document.has_key?('format') and document['format'].respond_to?('each')
      formats = document['format'].map{|f| f.parameterize}.join(" ").downcase
    end
    formats
  end

  def icon_cover(formats)
    if 'Blue-ray'.in?(formats)
      '/formats/blue-ray.svg'
    elsif 'Book'.in?(formats)
      '/formats/book.svg'
    elsif 'CD'.in?(formats)
      '/formats/cd.svg'
    elsif 'Conference'.in?(formats)
      '/formats/conference.svg'
    elsif 'DVD'.in?(formats)
      '/formats/dvd.svg'
    elsif 'Dissertation/Thesis	'.in?(formats)
      '/formats/dissertation-thesis.svg'
    elsif 'Image'.in?(formats)
      '/formats/image.svg'
    elsif 'Journal/Newspaper'.in?(formats)
      '/formats/journal-newspaper.svg'
    elsif 'LP'.in?(formats)
      '/formats/lp.svg'
    elsif 'manuscript-archive'.in?(formats)
      '/formats/manuscript-archive.svg'
    elsif 'Map/Globe'.in?(formats)
      '/formats/map-globe.svg'
    elsif 'Microform'.in?(formats)
      '/formats/microform.svg'
    elsif 'Musical Recording'.in?(formats)
      '/formats/musical-recording.svg'
    elsif 'Musical Score'.in?(formats)
      '/formats/musical-score.svg'
    elsif 'Non-musical Recording'.in?(formats)
      '/formats/non-musical-recording.svg'
    elsif 'Print'.in?(formats)
      '/formats/print.svg'
    elsif 'Software/Data'.in?(formats)
      '/formats/software-data.svg'
    elsif 'VHS'.in?(formats)
      '/formats/vhs.svg'
    elsif 'Video/Film'.in?(formats)
      '/formats/video-film.svg'
    else
      '1x1.png'
    end
  end

end
