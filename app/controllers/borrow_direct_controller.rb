require 'cgi'

# A controller for _redirecting_ users to BorrowDirect.
#
# * Forces authentication, looks up their barcode from auth process
# * If they don't have a barcode, can't do BD, error message.
# * Otherwise, pass them on with their barcode
#
# Any additional query parameters passed in, will be passed on to Borrow
# Direct as is.
# eg http://catalyst.library.jhu.edu/borrow_direct?query=smith
class BorrowDirectController < ApplicationController
  before_action :verify_user

  def index
    redirect_to borrow_direct_url
  end

  protected

  def borrow_direct_url
    bd_library_symbol = "JOHNSHOPKINS"

    borrower = HorizonBorrowerLookup.new.lookup(:id => current_user.horizon_borrower_id )
    barcode  = borrower[:barcode]

    url = "https://#{APP_CONFIG["borrow_direct_host"]}/?LS=#{CGI.escape bd_library_symbol}&PI=#{CGI.escape barcode}"

    unless request.query_string.blank?
      url = url + "&" + request.query_string.gsub('+', '%20')
    end

    return url
  end

  # Needs to be logged in, AND needs to have a Horizon borrower account with barcode.
  def verify_user
    unless current_user
      # For borrow_direct redirect, we redirect directly to shibboleth_login_url,
      # to force JHED login -- we don't want our default login page that allows
      # other methods of login for this action.

      redirect_to shibboleth_login_url(:referer => request.fullpath)
      return
    end

    unless current_user.horizon_borrower_id
      # render in before filter will stop subsequent action processing.
      render :template => "application/no_horizon_borrower_id_error"
      return
    end

    unless current_user.jhed_lid
      # Technically BD would work fine with a user with a barcode but
      # no JHED. However, there's been a policy decision to only forward
      # people to BD if they have a JHED _and_ a barcode. So we make sure
      # they still don't get in by being logged into Catalyst with barcode-only first.
      # 2014 May.

      message =  <<-EOS
      <p>Your borrower account does not have a JHED login associated with it.
         An associated JHED login is required for BorrowDirect.</p>
      <p>This may be a software error, we're sorry. Please contact your library help desk if you
        should have access, and include this information:</p>
      <ul>
        <li>Account name: #{ERB::Util.html_escape current_user.try(:name)}</li>
        <li>Horizon borrower ID: #{ERB::Util.html_escape current_user.horizon_borrower_id}</li>
        <li>Catalyst user ID: #{ERB::Util.html_escape current_user.id}</li>
      </ul>
      EOS
      message = message.html_safe

      logger.warn("BorrowDirect missing JHED error: #{message}")

      render :template => "application/message", :locals =>
        {:title => "We're sorry, BorrowDirect is not available to your account",
         :message => message
       }

    end

  end

end
