require 'horizon_borrower_lookup'
require 'hip_config'

# Custom home-grown auth based on what used to be AuthLogic over-rides,
# guided by http://asciicasts.com/episodes/250-authentication-from-scratch
class UserSessionsController < ApplicationController
  layout :determine_layout

  # the login screen, default view
  def index
    # so the login form can capture it and pass it on, so we can
    # return there.
    @referer = params[:referer] || request.referer
  end

  # This method gets called on login form submit
  def create
    begin
      # In case they were already logged in and calling login again,
      # destroy current session neccesary to accidentally somehow
      # mix up their credentials.
      session.delete(:current_user_id)
      session.delete(:current_user_horizon_id)
      session.delete(:hip_session_id)


      borrower = HorizonBorrowerLookup.new.lookup(:barcode => params[:barcode], :pin =>  params[:pin])
      #::Rails.logger.info("Barcode login: #{params[:barcode]}, looked up: #{borrower.inspect}")

      unless ( borrower )
        # Didn't find a borrower at all.
        flash.now[:error] = "Barcode/PIN not found. Check your entry and try again, or contact the Circulation desk at your home library for help."
        render :action => :index
        return
      else
        user = find_existing_account(borrower)
        # If we couldn't find one, we create one.
        user = create_new_account(borrower) unless user

        # And fill account with current values from Horizon, in case
        # they've changed.
        user.attributes = {:name => borrower[:name],
                           :horizon_borrower_id => borrower[:horizon_borrower_id], :jhed_lid => borrower[:jhed_lid],
                           :hopkins_id => borrower[:hopkins_id]}

        # Mark their last login
        user.last_login_at = Time.now

        user.save!

        login!(user)

        redirect_to sanitize_redirect_url
      end
    rescue HorizonBorrowerLookup::UnavailableError, ActiveRecord::ActiveRecordError => exception
      log_error(exception)
      flash.now[:error] = exception.message
      render :action => :index
    end

  end

  # This method is called from a Shibboleth-protected URL, so we get
  # Shib attributes in ENV. This method is callable becuase we map
  # /shibboleth_login to it in our routes.rb. And we Shibboleth-protect
  # /shibboleth_login in apache conf, to make sure we get shib headers.
  def shibboleth_create
    begin
      # In case they were already logged in and calling login again,
      # destroy current session neccesary to accidentally somehow
      # mix up their credentials.
      session.delete(:current_user_id)
      session.delete(:current_user_horizon_id)
      session.delete(:hip_session_id)

      jhed_lid = request.env['eppn']
      if jhed_lid.nil? and ( Rails.env.development? or Rails.env.test? )
        jhed_lid = ENV['FORCE_DEFAULT_JHED']
      end

      # If we didn't get a JHED LID, something is horribly wrong.
      raise ActiveRecord::ActiveRecordError.new("No authorized JHED information received, something has gone wrong.") unless jhed_lid
      # strip off the @johnshopksins.edu
      jhed_lid = jhed_lid.sub(/\@johnshopkins\.edu$/, '')

      hopkins_id = request.env['hopkinsID'] # mapped in /etc/shibboleth/attributes_map.xml
      email = request.env['mail']
      name = request.env['cn'] # cn == complete name

      # Look up a horizon borrower account by JHED we got, to get a horizon
      # borrowerID, which we'll also use. Trying to make sure if they didn't used
      # to have a JHED in horizon but do now, we still re-use their existing account.
      borrower = HorizonBorrowerLookup.new.lookup(:other_id => jhed_lid)
      hopkins_id ||= borrower[:hopkins_id] if borrower


      existing_account_conditions = {:jhed_lid => jhed_lid, :hopkins_id => hopkins_id}
      if borrower && borrower[:horizon_borrower_id]
        existing_account_conditions[:horizon_borrower_id] =  borrower[:horizon_borrower_id]
      end

      # Now try to find an existing BL account with that JHED and/or HopkinsID.
      user = find_existing_account(existing_account_conditions)

      # Don't allow logins that can't be matched to a horizon borrower... unless
      # we're asked to allow this with &allow_no_horizon=true, doh. allow_no_horizon
      # used for allowing Bologna/Nanjing people to login for article search even
      # though they have no horizon account.
      if ( borrower.nil? && params[:allow_no_horizon] != "true")
        msg = "No Library Borrower account could be found for JHED login ID #{jhed_lid}. Please contact the Circulation Desk at your home library for help."
        flash[:error] = msg
        redirect_to :action => :index, :referer => @referer

        logger.warn(msg)

        return
      end

      # If no user exists, create one, it'll be saved later after updating.
      user = User.new(:login => jhed_lid, :jhed_lid => jhed_lid) unless user

      # Make sure local User account is filled out with all information from
      # jhed login or horizon borrower lookup. Might be a new account, or
      # might be an existing one but we still want to freshen it up with
      # latest data we just looked up, in case it's changed.

      user.horizon_borrower_id = borrower[:horizon_borrower_id] if borrower

      user.jhed_lid = jhed_lid
      user.name = name
      user.email = email
      user.hopkins_id = hopkins_id

      # Mark their last login
      user.last_login_at = Time.now

      user.save!

      # Log them in, and send them back.
      login!(user)

      redirect_to sanitize_redirect_url
   rescue HorizonBorrowerLookup::UnavailableError, ActiveRecord::ActiveRecordError => exception
     log_error(exception)
     # Send em back to login page with an error
     flash[:error] = exception.message
     redirect_to :action => :index, :referer => @referer
   end

  end

  # This is the action called on 'logout'.
  # We need to redirect to IT@JH SSO sign-out, as per IT policy communicated
  # to me on 2 Dec 2009. Also destroy local Shib SP cookies to effect that
  # logout.
  def destroy
    @current_user = nil

    # Remove the hip_session id, since that kind of goes along
    # with login. Yeah, this code is far away from where hip_session
    # gets created making for confusion, sorry.
    #session.delete(:hip_session_id)
    # actually, destroy the whole damn session, why not, we're redirecting
    # them elsewhere anyway.
    reset_session

    # Remove shib cookies to log out of local Shib Service Provider.
    # But this doesn't work anyway, not sure why.
    #cookies.keys.find_all {|k| k =~ /^_shibsession_/ || k =~ /^_shibstate_/}.each { |cookie| cookies.delete(cookie) }

    redirect_to "https://login.johnshopkins.edu/cgi-bin/logoff.pl"

  end

  protected
  # try to find an existing user with same IDs, find an account with
  # any of the ID's mentioned.
  def find_existing_account(hash)
    # Need a lookup key, or we have nothing
    return nil unless (hash.keys & [:jhed_lid, :hopkins_id, :horizon_borrower_id]).length > 0

    queries = []
    [:hopkins_id, :jhed_lid, :horizon_borrower_id].each do |key|
      queries << "#{key} = :#{key}" if hash[key]
    end

    # There shouldn't be multiples, but just in case we do an ORDER BY,
    # so we'll always get the same one if there are multiples (the earliest created one)
    return User.where( queries.join(" OR "), hash).order(:created_at, :id).first
  end

  def create_new_account(borrower)
    loginname = borrower[:jhed_lid] || "bor." + borrower[:horizon_borrower_id]

    User.create(:login => loginname,
                :horizon_borrower_id => borrower[:horizon_borrower_id],
                :hopkins_id => borrower[:hopkins_id],
                :jhed_lid => borrower[:jhed_lid],
                :name => borrower[:name])
  end

  # Shared code between JHED login and barcode login,
  # to properly register user as logged in
  def login!(user)
      # Store both local ID and horizon_borrower_id
      # to try and prevent mismatches from cookies.
      session[:current_user_id]  = user.id
      session[:current_user_horizon_id] = user.horizon_borrower_id

      # Blacklight requires this to migrate guest bookmarks over
      # to permanent bookmarks where needed. It's not documented
      # well exactly how this works with non-Devise auth, but appears
      # to be working.
      transfer_guest_user_actions_to_current_user
  end

  # used to be in Rails public api, now we have to provide it ourselves
  def log_error(exception)
     logger.error(
        "\n#{exception.class} (#{exception.message}):\n  " +
        Rails.backtrace_cleaner.clean(exception.backtrace).join("\n  ") + "\n\n"
      )
  end

  protected

  def determine_layout
    return false if params[:modal]
    super
  end

end
