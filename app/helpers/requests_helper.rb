module RequestsHelper
  require 'uri'

  # Tell the user a bit about what's going on
  def request_head_notes

    notes = []
    # DISABLED: The "queue position" from HIP is unreliable, it is sum
    # of all pending requests on BIB, not item. Which was same in HIP
    # native interface, but new more prominent display was confusing people,
    # so we simply eliminate this message from request panel.
    # http://jira.projectblacklight.org/jira/browse/JHUBL-123
    #
    # TODO (if position in queue was reliable in the first place!):
    # If queue_position is 1, but item is currently checked out, let
    # em know they'll have to wait for a recall. But currently we don't
    # have easy access to knowing if item is currently checked out, HIP
    # doesn't tell us, doh.
    #if @ils_request.queue_position > 1
    #  notes << {:class=>"note", :text => "...is currently on loan, you will be #{@ils_request.queue_position.ordinalize} on the waiting list."}
    #end

    if @ils_request.try(:closed_stack_access_location) ||
        ( @ils_request.try(:available_locations).try(:length) == 1 && @ils_request.available_locations.first =~ /special collection/i)
      notes << {:class=>"note", :text => "This item can only be used in the Special Collections reading room, located on M Level of the BLC."}
    end

    return notes
  end

  # maybe we were sent a referer in params, otherwise we do our
  # best to come up with something reasonable.
  def request_done_path
    if params["referer"]
      begin
        # for security, we make sure it's a partial URL that is internal
        # to our app.
        u = URI.parse(params["referer"])

        u.host = nil
        u.scheme = nil
        url = u.to_s
        return url if url.starts_with?( root_path )
      rescue Exception => e
        logger.warn("Referer is not a legit url?: #{e.inspect}\n    HTTP User-Agent:    #{request.headers["User-Agent"]}\n    HTTP Referer: #{request.headers["Referer"]}")
      end
    end
    if @ils_request && @ils_request.bib_id
      return solr_document_path("bib_#{@ils_request.bib_id}")
    end

    return search_catalog_path

  end

  def special_collection_request_url(document, holding)
    aeon_host = URI(ENV['AEON_URL']).hostname

    params = { genre: :book, Action: 10, Form: 30 }
    params[:title] = document['title_display']
    params[:rfe_dat] = document['id'].partition('_').last
    params[:callnumber] = holding.call_number
    params[:callnumber] += ' ' + holding.copy_string if holding.copy_string
    params[:location] = holding.location.internal_code
    params[:site] = holding.special_collection_site
    params[:itemnumber] = holding.localInfo.fetch('ibarcode', '')
    params[:sublocation] = holding.localInfo.fetch('moravia_rmst', '')
    params[:ItemAuthor] = document['author_display'].join('; ') if document['author_display']
    params[:ItemPlace] = document['published_display'].join('; ') if document['published_display']
    params[:ItemDate] = document['pub_date'].join('; ') if document['pub_date']
    value = URI::HTTPS.build({host: aeon_host, path: '/logon', query: params.to_query})
    value.to_s
  end

end
