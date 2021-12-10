require 'hip_pilot'
require 'ray'

class RequestsController < CatalogController

  before_action :init_hip_pilot
  around_action :catch_request_failure


  # The request submission form
  def new
    @response, @document = search_service.fetch(params[:id])

    # The individual item object for use in the view. May wind up
    # with nil for copy/item multi-level holdings, bah.
    @holding = @document.fetch_holding(params[:item_id])
    ray(@holding)

    horizon_bib_id = @document.ils_bib_id

    @available, @exact_copy = check_availability?(@document, @holding)
    @show_borrow_direct = show_borrow_direct?(@document)

    if @exact_copy
      @ils_request = HipPilot::Request.new(:bib_id => horizon_bib_id, :item_id => params[:item_id])
    else
      @ils_request = HipPilot::Request.new(:bib_id => horizon_bib_id, :item_id => '')
    end

    @hip_pilot.init_request(@ils_request)
  end

  # Submit request and show confirmation page
  def create
    @response, @document = search_service.fetch(params[:id])

    horizon_bib_id = @document.ils_bib_id
    horizon_item_id = (params[:exact_copy] == true || params[:exact_copy] == 'true' ) ? params[:item_id] : nil

    params[:ils_request][:bib_id] = horizon_bib_id
    params[:ils_request][:item_id] = horizon_item_id

    @ils_request = HipPilot::Request.new( params[:ils_request] )
    ray('ils_request: ', @ils_request)
    success_xml = @hip_pilot.submit_request(@ils_request)
    @pickup_location = success_xml.at_xpath("./pickup_location/text()").to_s
  end

  protected

    # makes sure user is logged in, and inits a hip pilot object if so
    def init_hip_pilot
      if current_user && current_user.horizon_borrower_id
        @hip_pilot = HipPilot.new(current_user, session)
      elsif current_user && ! current_user.horizon_borrower_id
        # Logged in user has no connection to horizon borrower account (maybe Bologna user),
        # they can't make requests. render here makes Rails stop further action processing.
        render :template => "application/no_horizon_borrower_id_error"
      elsif request.xhr?
        # ajaxy request, redirecting to login isn't going to work right,
        # give em a 403 telling em we can't do it. Body contains a data-force-login,
        # that our JS code will catch and redirect to authentication, and a data-request-url
        # that our JS code will use to... do overly complex hacky stuff so when they are done
        # logging in, they get the request modal again.

        flash[:notice] = "Please log in to place a request."

        body = "<span data-force-login='#{new_user_session_url}' data-request-path='#{request.path}'>Request requires authentication, which can't be done over an xhr request.</span>"

        render html: body.html_safe
      else
        # raise the exception that will cause redirect to login screen.
        flash[:notice] = "Please log in to place a request." and raise Blacklight::Exceptions::AccessDenied
      end
    end

    def catch_request_failure
      yield
    rescue HipPilot::LoginFailure => e
      @exception = e
      ray(@exception)
      render "request_login_failure"
    rescue HipPilot::RequestFailure => e
      @exception = e
      ray(@exception)
      render "request_failure"
    end

    def show_borrow_direct?(document)
      return document.respond_to?(:to_openurl) &&
        document.to_openurl.referent.format != "journal" &&
        document.respond_to?(:to_holdings) &&
        ! document.to_holdings.find { |h|
          %w(ecageki eofart eofms esmanu esgpms esarck esarc).include?(h.collection.try(:internal_code)) &&
            h.collection.try(:display_label) !~ /(reserves?)|(non-circulating)/i
        }
    end

    def check_availability?(document, holding)
      ray('Holding: ', holding)

      # The item is available so just return true
      if holding.status.try(:display_label) == "Available"
        ray('Available')
        return [true, true]
      end

      # The item is not available, but it's also a volume so just return false
      if holding.status.try(:display_label) != "Available" && (! holding.copy_string.nil? && holding.copy_string.include?('v.'))
        ray('Not available or volume')
        return [false, true]
      end

      # Check to make sure the document can respons to to_holdings
      if ! document.respond_to?(:to_holdings)
        ray('Respond to holding false')
        return [false, true]
      end

      # Let's check to see if any other copies are available if so then we will show the request form and send back a flag
      # to request any available copy rather than a specific one
      status = false
      # TODO: This needs to check for all children of document and not just holding

      document.to_holdings.each do |doc_holding|
        if doc_holding.has_children?
          ray('Getting children holdings')
          doc_holding = document.to_holdings_for_holdingset(doc_holding.id)
          if doc_holding.find { |h| h.status.try(:display_label) == "Available" }
            status = true
            ray('Status: ', status)
            return [status, false]
          end
        else
          ray('No children')
          if ! doc_holding.copy_string.nil? && doc_holding.status.try(:display_label) == "Available"
            status = true
            ray('Status: ', status)
            return [status, false]
          end
        end
      end
      ray('Status: ', status)
      return [status, true]

      # if holding.has_children?
      #   ray('Getting children holdings')
      #   if document.to_holdings_for_holdingset(holding.id).find { |h| h.status.try(:display_label) == "Available" }
      #     status = true
      #   end
      # else
      #   if holding.status.try(:display_label) == "Available"
      #     ray('No children')
      #     status = true
      #   end
      # end
      # ray('Status: ', status)
      # return [status, false]

    end


end
