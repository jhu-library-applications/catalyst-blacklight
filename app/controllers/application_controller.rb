# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'render_unstemmed_constraint_helper'
require 'ipaddr_range_set'
require 'hip_pilot'
require 'rails_stackview'

class ApplicationController < ActionController::Base
  layout 'blacklight'

  # Adds a few additional behaviors into the application controller
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  protect_from_forgery
  helper :all # include all helpers, all the time
  helper RenderUnstemmedConstraintHelper

  rescue_from HipPilot::HipDisabled, :with => :hip_disabled_message

  ##TODO: review this hack that allows a security bypass (part of rails 5 upgrade)
  ActionController::Parameters.permit_all_parameters = true
  ActionController::Parameters.action_on_unpermitted_parameters = :raise


  skip_before_action :verify_authenticity_token, :only => [:hip_disabled_message]

  def current_user
    if @current_user.nil? && session[:current_user_id]
      # cheesy way to look up the userID only if we have it, return nil if it
      # doens't exist. Look up on both local ID and horizon borrower ID stored
      # in session, to prevent cookie mismatches logging wrong person in
      # when db changes.  Unless horizon_borrower_id is nil cause we have a SAIS bologna
      # user, sign.
      conditions = {User.primary_key.to_sym => session[:current_user_id]}
      conditions[:horizon_borrower_id] = session[:current_user_horizon_id] if session[:current_user_horizon_id]

      @current_user = User.where(conditions).first
    end
    return @current_user
  end
  helper_method :current_user

  # The guest_user setup will, on-demand, create a temporary 'guest'
  # user in the db to represent a not-yet-logged-in user, so they can
  # still save bookmarks and such for their session.
  #
  # The particular semantics and methods we implement are those neccesary
  # for compatibility wtih Blacklight, see https://github.com/projectblacklight/blacklight/wiki/Blacklight-3.7-release-notes-and-upgrade-guide
  # needs #guest_user and  #current_or_guest_user
  def current_or_guest_user
    current_user || guest_user
  end
  helper_method :current_or_guest_user

  # The guest_user setup will, on-demand, create a temporary 'guest'
  # user in the db to represent a not-yet-logged-in user, so they can
  # still save bookmarks and such for their session.
  #
  # The particular semantics and methods we implement are those neccesary
  # for compatibility wtih Blacklight, see https://github.com/projectblacklight/blacklight/wiki/Blacklight-3.7-release-notes-and-upgrade-guide
  # needs #guest_user and  #current_or_guest_user
  def guest_user
    unless defined? @guest_user
      if session[:guest_user_id] && (user = User.where(:id => session[:guest_user_id]).first)
        @guest_user = user
      else
        @guest_user = create_guest_user!
        session[:guest_user_id] = @guest_user.id
      end
    end
    return @guest_user
  end
  helper_method :guest_user

  # Creates a mock user in the db to represent a 'guest' not yet logged in,
  # to make Blacklight bookmarks still work with not yet logged in people.
  def create_guest_user!
    # bah, this may not be entirely guaranteed to be unique
    # but it would be hard for it to collide, good enough. Actually
    # if the rails session id isn't unique, it's gonna cause problems
    # for more than just us, we should be good with just that even.
    unique_token = "#{request.session_options[:id]}_#{(Time.now.to_f * 1000.0).to_i}_#{Process.pid}"

    new_user = User.new.tap do |u|
      u.login = "GUEST_USER_#{unique_token}"
      u.guest = true
      u.save!
    end
  end

  def verify_user
    unless current_user
      flash[:notice] = "Please log in to view your profile."
      raise Blacklight::Exceptions::AccessDenied
    end
    unless current_user.horizon_borrower_id
      # render in before filter will stop subsequent action processing.
      render :template => "application/no_horizon_borrower_id_error"
    end
  end
  protected :verify_user


  # It's hard to keep these up to date, but we try to track them on:
  # https://wiki.library.jhu.edu/display/COLL/IP+Ranges+at+JHU
  $local_ip_range = IPAddrRangeSet.new(
    IPAddrRangeSet::LocalAddresses, # internal IP addresses, not routed on internet
    # Homewood and others 128.220.*.*, excluding 128.220.106.226, which is alumni proxy
    ("128.220.0.0".."128.220.106.225"),
    ("128.220.106.227"..."128.221.0.0"),
    "128.244.*.*",        # APL
    "162.129.*.*",        # (JHMIB)
    "65.111.76.4",        # (Howard County General Hospital)
    "192.124.118.140",    # Mt. Washington
    "65.210.63.19",       # (Suburban Hospital)
    "209.124.166.20",     # (KKI)
    "67.151.28.*",        # (Sibley Hospital)
    ("193.206.22.225".."193.206.22.254"), # Internat, Bologna
    ("202.119.55.1".."202.119.55.28") # Internat, Nanjing

    # No longer in TS list as of 15 Jul 2013
    #"204.91.130.*",       # (JHPIEGO)
    #("12.110.113.0".."12.110.113.63"),  # (JH Healthcare)
    #"151.200.174.19",     # (Suburban Hospital),
  )

  # Is client from a recognized local IP addr, OR logged in?
  # uses global variable $local_ip_range set just above
  # this method def.
  def local_or_logged_in?
    current_user || $local_ip_range.include?( request.remote_ip )
  end
  helper_method :local_or_logged_in?

  def hip_disabled_message
    @title = "Patron account features unavailable"
    @message = JHConfig.params[:disable_hip_message] || "Sorry, patron account features are currently unavailable for maintenance."
    # can't use status 503 or it messes up our ajaxy dialog, sorry.
    render "message"
  end

  ##
  # Returns a local URL path component to redirect to after an action.
  # Will be taken from referer query param or referer HTTP header, in that
  # order, but only used if allowable non-blacklisted internal URL, otherwise
  # root_path is used.
  #
  # `redirect_path` performs some basic checks to ensure the URL is internal
  #  and will not cause redirect loops.
  def sanitize_redirect_url
    referer = params[:referer].blank? ?  request.referer : params[:referer]

    if referer && (referer =~ %r|^https?://#{request.host}#{root_path}| ||
        referer =~ %r|^https?://#{request.host}:#{request.port}#{root_path}|)
      #self-referencing absolute url, make it relative
      referer.sub!(%r|^https?://#{request.host}(:#{request.port})?|, '')
    elsif referer && referer =~ %r|^(\w+:)?//|
      Rails.logger.debug("#post_auth_redirect_url will NOT use third party url for post login redirect: #{referer}")
      referer = nil
    end

    if referer && referer_blacklist.any? {|blacklisted| referer.starts_with?(blacklisted)  }
      Rails.logger.debug("#post_auth_redirect_url will NOT use a blacklisted url for post login redirect: #{referer}")
      referer = nil
    elsif referer && referer[0,1] != '/'
      Rails.logger.debug("#post_auth_redirect_url will NOT use partial path for post login redirect: #{referer}")
      referer = nil
    end

    return referer || root_path
  end
  protected :sanitize_redirect_url

  ##
  # Returns a list of urls that should /never/ be the redirect target for
  # post_auth_redirect_url. login and logout.
  def referer_blacklist
    [new_user_session_path, destroy_user_session_path]
  end
  protected :referer_blacklist

  protected

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
end
