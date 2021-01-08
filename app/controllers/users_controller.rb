require 'hip_pilot'

class UsersController < CatalogController

  before_action :init_hip_pilot
  before_action :verify_user, :only => [:itemsout, :requests, :show]

  rescue_from HipPilot::ConnectionError, :with => :show_connection_error
  rescue_from HipPilot::HipDisabled, :with => :hip_disabled_message


  # Override new and create from BL plugin, we don't do that, we just
  # automatically create accounts on login from external auth.
  def new
    render(:status => 401 , :text => "User creation not allowed.")
  end
  def create
    render(:status => 401 , :text => "User creation not allowed.")
  end

  def show
    @notes = @hip_pilot.notes
    @total_fines = @hip_pilot.total_fines
    @profile = @hip_pilot.profile
  end

  # Only one piece of info we allow the user to update in their account
  # right now, their email. And we use the HipPilot to update it via
  # hip.
  def update
    email = params[:user][:email]

    @hip_pilot.update_email(email)

    # Have no idea why or if it's even true that it may take 24 hours
    # to take effect, but copied that warning from current HIP.
    flash[:notice] = "Your email address has been changed. In some cases it may take up to 24 hours for your new email address to take effect."
    redirect_to :action => :show
  rescue HipPilot::ProfileUpdateFailure  => e
    flash[:error] = "Sorry, could not update email address: '#{e.public_message}'"
    redirect_to :action => :show
  end

  def itemsout
    @items = @hip_pilot.items_out()
    # sort em better than hip does, sort asc by due date, then desc checkout date asc
    @items.sort! do |a, b|
      # Have to deal with any of the dates being missing, not supplied
      # by HIP/Horizon. This is messy code, sorry.

      if a.date_complete.nil? || b.date_complete.nil?
        0
      else
        due_comp = a.date_complete.to_time <=> b.date_complete.to_time

        if due_comp == 0
          #checked out for same due dates
          if a.date_initiated.nil? || b.date_initiated.nil?
            0
          else
            (a.date_initiated.to_time <=> b.date_initiated.to_time)
          end
        else
          due_comp
        end
      end
    end
  rescue RSolr::Error::Http, HipPilot::ConnectionError => e
    # Those with hundreds of items out we have problems with in current
    # design. HIP might timeout, OR we might generate a Solr query that
    # is too many bytes or query clauses for Solr to handle. In either case,
    # we want to rescue to at least show a nice error screen with nav bar.
    # Long term solution to actually show them their items out is unclear.
    Rails.logger.warn("UserController#itemsout: Could not fetch items out: #{e.inspect}")
    @fetch_error = e
  end

  def requests
    @items_available = @hip_pilot.requests_available()
    @items_pending = @hip_pilot.requests_pending()
    # fetch solr documents and attach please
    all_items = (@items_available + @items_pending).uniq
    (@solr_response, @documents) = add_solr_documents!(all_items)
  end

  # if an item_out is present, it's renew one item, otherwise renew all
  def renew
    item_list =
      if params[:item_out]
        [  HipPilot::ItemOut.new(params[:item_out])  ]
      else
        @hip_pilot.items_out()
      end

    (renewed, renew_errors, status_msg) = @hip_pilot.renew(item_list)

    if item_list.length == 1 && renewed.length == 1
      flash[:notice] = "Item renewed. #{status_msg}"
    elsif item_list.length == 1 && renewed.length == 0
      flash[:error] = "Could not renew item. #{status_msg}"
    elsif item_list.length == renewed.length
      flash[:notice] = "All #{renewed.length} items renewed. #{status_msg}"
    else
      flash[:error] = "#{renewed.length} of #{item_list.length} items renewed. #{status_msg}"
    end

    # store the item id's in flash, so the itemsout screen can pleasantly
    # tell a user her item was renewed.
    renewed_items = renewed.collect &:item_id

    flash[:renewed_item_ids] = renewed_items
    flash[:not_renewed_item_ids] = (item_list.collect &:item_id) - renewed_items
    flash[:renew_errors] = renew_errors

    redirect_to :action => "itemsout"
  end

  protected

  def show_connection_error(e)
    @for_user = e.for_user if e.respond_to?(:for_user)

    if e.kind_of?(HipPilot::LoginFailure)
      @message = "We're sorry, your borrower account is not available, it may be disabled or expired."
    end

    render "connection_error", :status => 502
  end

  # accepts a list of usually HipPilot::Transactions, but really anything
  # with a #bib_id method, and a #solr_document= method. Fetches all the SolrDocuments
  # with those ids, attaches the corresponding SolrDocument to each Transaction.
  # returns a pair of [@solr_response, @documents] from the solr fetch to
  # get those documents.
  def add_solr_documents!(transactions)
    (solr_response, documents) = search_service.fetch(transactions.collect {|i| "bib_" + i.bib_id})

    transactions.each do |item|
      item.solr_document = documents.find {|d| d['id'].sub(/^bib_/,'') == item.bib_id }
    end

    return [solr_response, documents]
  end

  def init_hip_pilot
    @hip_pilot = HipPilot.new(current_user, session)
  end


end
