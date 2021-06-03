require 'cgi'
require 'open-uri'
require 'date'
require 'time'
require 'httpclient'
require 'tzinfo'

require 'hip_config'
require 'horizon_borrower_lookup'


# TODO: Make sure checkout and due dates with times work

class HipPilot
  attr_accessor :current_user

  @@timeout = 10 # seconds. HIP is slow sometimes.
  @@renewal_timeout = 120 # seconds, renew all can take a really long time, sorry.

  #need to provide the current logged in BL user, so we can get HIP borrower#
  #etc if needed. Need to provide the current controller session object,
  # so we can store our hip session there.
  def initialize(current_user, rails_session, options = {})

    # HIP has been marked as disabled, perhaps because we are
    # doint Horizon maintenance. Refuse to contact HIP, instead
    # raise, and we'll give them a nice error message.
    if JHConfig.params[:disable_hip]
      raise HipDisabled
    end


    self.current_user = current_user
    @rails_session = rails_session

    @hip_base_url = options[:hip_base_url] || HipConfig.ipac_base

  end

  # returns list of HipPilot::Transaction
  def items_out
    xml = xml_for(items_out_url)


    xml.xpath("/*/itemsoutdata/itemout").collect do |ixml|
      ItemOut.new(
        :bib_id => at_xpath_text(ixml, "key"),
        :item_id => at_xpath_text(ixml, "ikey"),
        :item_barcode => at_xpath_text(ixml, "holdingkey"),
        :date_initiated => safe_date_parse(ixml.at_xpath("ckodate")),
        :date_complete =>
          unless (time = ixml.at_xpath("duetime").text).blank?
            Time.strptime(ixml.at_xpath("duedate").text() + " " + time, "%m/%d/%Y %H:%M %p")
          else
            safe_date_parse(ixml.at_xpath("duedate"))
          end,
        :times_renewed => at_xpath_text(ixml, "numrenewals"),
        :label => at_xpath_text(ixml, "disptitle"),
        # fragile, rely on cell location, but we need it for
        # recognizing BorrowDirect to avoid trying to renew BorrowDirect since
        # HIP has a bug if you try. Argh. https://issues.library.jhu.edu/browse/HELP-10671
        :collection_str => at_xpath_text(ixml, "cell[1]/data/text")
      )
    end
  end

  # returns list of HipPilot::Transaction
  def requests_pending
    xml = xml_for(requests_url)

    xml.xpath("/*/holdsdata/waiting/waitingitem").collect do |ixml|
      Transaction.new(
        :bib_id => ixml.at_xpath("key").text(),
        :item_id => ixml.at_xpath("itemkey").text(),
        :queue_position => ixml.at_xpath("queuepos").text().to_i,
        :date_initiated => safe_date_parse(ixml.at_xpath("dateplaced")),
        :date_complete => safe_date_parse(ixml.at_xpath("dateexpires")),
        :pickup_location => ixml.at_xpath("pickuploc").text(),
        :label => ixml.at_xpath("disptitle").text(),
        #these are fragile xpaths,oh well.
        :collection_str  => ixml.at_xpath("cell[1]/data/text").text(),
        :item_status => ixml.at_xpath("cell[3]/data/text").text(),
        :due_date => safe_date_parse(ixml.at_xpath("cell[4]/data"))
       )
    end.sort do |a, b|
      a.date_initiated <=> b.date_initiated
    end
  end

  def requests_available
    xml = xml_for(requests_url)
    xml.xpath("/*/holdsdata/ready/readyitem").collect do |ixml|
      Transaction.new(
        :bib_id => ixml.at_xpath("key").text(),
        :item_id => ixml.at_xpath("itemkey").text(),
        :date_initiated => safe_date_parse(ixml.at_xpath("dateplaced")),
        :date_complete => safe_date_parse(ixml.at_xpath("dateexpires")),
        :pickup_location => ixml.at_xpath("pickuploc").text(),
        :label => ixml.at_xpath("disptitle").text()
        )
    end.sort do |a, b|
      a.date_complete <=> b.date_complete
    end
  end

  def total_fines
    el = xml_for(fines_and_notes_url).at_xpath("/*/blockdata/totalamount")
    return nil unless el # no xml element?
    fines = el.text()
    if fines =~ /^\w*\$?0+\.?0*\w*$/
      # zero
      return nil
    else
      return fines
    end
  end

  def notes
    xml = xml_for(fines_and_notes_url)
    xml.xpath("/*/blockdata/block").collect do |nxml|
      fee = nxml.at_xpath("amount").text()
      if fee =~ /^\w*\$?0+\.?0*\w*$/
        fee = nil #zero
      end
      Note.new(
        :reason => nxml.at_xpath("reason").text(),
        :note => nxml.at_xpath("title").text(),
        :date => safe_date_parse(nxml.at_xpath("duedate")),
        :fee => fee
      )
    end
  end

  def profile
    xml = xml_for(profile_url).xpath("/*/patroninfo")


    return Profile.new(
      :name => at_xpath_text(xml, "name/full"),
      :phone => at_xpath_text(xml, "phones/phone/full[1]"),
      :address_array => xml.xpath("addresses/address[1]/*[self::street or self::citystate or self::postal]").to_a.collect{|a| a.text() unless a.text().blank?}.compact,
      :home_library => at_xpath_text(xml, "location"),
      :card_expiration => safe_date_parse(xml.at_xpath("cardexpiresdate")),
      :email => at_xpath_text(xml, "emailaddresses/emailaddress[1]/email")
    )
  end

  def xml_for(url)
    @cached_xml ||= {}
    @cached_xml[url] ||= get_xml_with_login(url)
  end

  def items_out_url
    url = URI.parse(@hip_base_url)

    uri_query_merge(url, "menu" => "account", "submenu" =>"itemsout")

    return url
  end

  def profile_url
    url = URI.parse(@hip_base_url)
    uri_query_merge(url, "menu" => "account", "submenu" => "info")
  end



  def requests_url
    url = URI.parse(@hip_base_url)
    uri_query_merge(url, "menu" => "account", "submenu" =>"holds")

    return url
  end

  def fines_and_notes_url
    url = URI.parse(@hip_base_url)
    uri_query_merge(url, "menu"=>"account", "submenu"=>"blocks" )
    return url
  end

  ##
  # Making requests. first call #init_request( request_obj )
  # to make sure the request is possible, and fill in values such
  # as available pickup locations.
  # then fill in optional fields like comments or chose a non-default
  # pickup location, and call #submit_request( request_obj ).
  def init_request( request )
    url = URI.parse(@hip_base_url)
    uri_query_merge(url, "menu" => "request",
        "bibkey"  => request.bib_id,
        "itemkey" => request.item_id,
        "time"    =>Time.now.to_i) # HIP wants unix epoch time of 'now' in 'time' param

    xml = get_xml_with_login(url)

    # Okay, sometimes horizon gives us a multiple-choice page here
    # for method of delivery. Except here at JHU as of now, as far
    # as I can tell, this page only ever offers ONE choice,
    # 'closed stack' special collections, which we have also hard-coded
    # to always tell the user the location is MSEL Special Collections.
    # So we basically just skip that page,
    # if that's the situation -- otherwise we're going to throw an error,
    # the code can't handle more complicated situations I don't think
    # ever occur.
    # https://hip-test.library.jhu.edu/ipac20/ipac.jsp?session=1E9D4802311J5.17&profile=general&request_type_choice=2&return_search=Cancel&cl=PlaceRequestjsp
    if (select = xml.at_xpath(".//select_request_type"))
      if select.at_xpath("radio") || ! select.at_xpath("csa_msg")
        raise Exception.new("Sorry, a software error has occured. Software does not support request for this item.  item id #{request.item_id} ")
      end
      # go past the screen
      url = URI.parse(@hip_base_url)
      uri_query_merge(url,
        "request_type_choice" => "2",
        "select_type" =>"Yes",
        "cl"          => "PlaceRequestjsp",
        )
      xml = get_xml_with_current_session(url)
    end



    if ( error_msg = xml.at_xpath("//alert/message"))
      raise RequestFailure.new( error_msg.text, current_user )
    end

    request_confirm = xml.at_xpath("//request_confirm")

    request.available_locations ||=
      request_confirm.xpath("./pickup_location/location").collect do |location_xml|
        # New hip gives us sub-nodes code and description, old HIP
        # only had a text node description. We try to make work for both.

        if code_xml = location_xml.at_xpath("./code")
          PickupLocation.new(code_xml.text, location_xml.at_xpath("./description").text())
        else
          # Old hip essentially uses the user-displayable description
          # as the 'code' for purposes of screen scraping HTTP interaction.
          # This whole branch can be removed when we don't want to support older
          # version of HIP anymore.
          PickupLocation.new(location_xml.text(), location_xml.text())
        end
    end

    # hip-supplied default
    if (expire_date = request_confirm.at_xpath("./request_expire_date") )
      request.expire_date = safe_date_parse(expire_date)
    end
    request.queue_position = request_confirm.at_xpath("./hold_queue_position").text().to_i + 1

    # hacky closed stack access, for our use of Horizon means can only be
    # viewed in special collections.
    if ( csa_loc = request_confirm.at_xpath("./csa_pickup_agency") )
      request.closed_stack_access_location = csa_loc.text
    end


    # These supply as default, but don't over-write if we already have ones

    # HIP supplies a suggested pickup location as a default, we want to respect --
    # but it supplies it using 'description' not 'code', we want to make it
    # code. And it sometimes supplies a suggestion that isn't actually allowed,
    # we don't want to try and use that.

    if (suggested_location = request_confirm.at_xpath("./selected/pickup/child::text()").to_s)
      if suggested_location.include? "SAIS"
        request.pickup_location ||= request.available_locations.find {|l| l.description.include?("SAIS")}.try(:code)
      else
        request.pickup_location ||= request.available_locations.find {|l| l.description == suggested_location}.try(:code)
      end
    end

    # And if pickup location is still blank, default to first avail.
    if request.pickup_location.blank? && request.available_locations.present?
      request.pickup_location = request.available_locations.first.try(:code)
    end

    request.item_display ||= request_confirm.at_xpath("./copy/child::text()").to_s

    # Do over-ride default value for notification_method, we need to get the
    # current one.
    request.notification_method = request_confirm.at_xpath("./notification_method/type/child::text()").to_s

    return request
  end

  # Returns Nokogiri XML of portion of HIP response containing success information.
  #bib=27026 item=131337
  #https://hip-test.library.jhu.edu/ipac20/ipac.jsp?session=1293462773XL9.1&profile=general&pickuplocation=test+-+Milton+S.+Eisenhower+Library&notifyby=e-mail&requestcomment=this+is+a+comment&request_finish=Confirm&cl=PlaceRequestjsp&aspect=none
  def submit_request(request)
    # HIP annoyingly keeps WHAT request you are submitting simply in session
    # state based on what you presented the 'confirm request' screen for.
    # So we've got to make sure to ask for that screen again, even though we
    # already asked for it once to present form to user, and then submit immediately
    # after that.

    init_request(request)

    url = URI.parse(@hip_base_url)

    uri_query_merge(url,
      "pickuplocation"  => request.pickup_location,
      "notifyby"        => request.notification_method,
      "requestcomment"  => request.comment,
      "request_finish"  => "Confirm",
      "cl"              => "PlaceRequestjsp")

    xml = get_xml_with_current_session(url)

    success = xml.at_xpath("//request_success")

    unless success
      Rails.logger.warn("HipPilot: Weird connection error in making request: #{xml.to_s}")
      raise ConnectionError
    end

    return success
  end

  def update_email(new_email)
    url = URI.parse(@hip_base_url)
    #https://hip-test.library.jhu.edu/ipac20/ipac.jsp?session=Q2O4337H47963.1&profile=general&newemailtext=rochkind22%40jhu.edu&updateemail=Update&menu=account&submenu=info&GetXML=1
    uri_query_merge(url,
      "profile" => "general",
      "newemailtext" => new_email,
      "updateemail" => "Update",
      "menu" => "account",
      "submenu" => "info"
      )

    xml = get_xml_with_login(url)

    # HIP refusing to change info in an official recognized way?
    if ( xml.at_xpath("/patronpersonalresponse/patroninfo/message/code/text()").to_s == "update_failed" )
      raise ProfileUpdateFailure.new(nil, xml.at_xpath('/patronpersonalresponse/patroninfo/message/reason/text()'))
    end

    # Otherwise, maybe a less expected error.
    unless ((changed = xml.at_xpath("/patronpersonalresponse/patroninfo/emailaddresses/emailaddress/email")) &&
            changed.text() == new_email)

      Rails.logger.warn("HipPilot: Could not change email in HIP at #{url} : #{xml.at_xpath('/patronpersonalresponse/patroninfo/message')}")
      raise ConnectionError
    end

    return new_email
  end

  # Argument is an ARRAY of ItemOut objects.
  # the 'barcode' in each object is actually used to communicate with
  # hip. The only way we have to know if the renewal was succesful is if
  # HIP has incremented the "times_renewed", so we use that too.
  # Returns a triple of:
  # 1) array of the ItemOut that were succesfully renewed.
  # 2) hash keyed by item id, value error message, of any renewal errors
  #    returned by HIP.
  # 3) Any HIP-reported status message
  def renew(items)
    renewed, errors = {}, {}

    items, excluded_bd_items = items.partition {|i| ! i.borrow_direct_item? }


    if items.present?
      url = URI.parse(@hip_base_url)
      uri_query_merge(url,
          :renewitems=>"Renew",
          :menu=>"account",
          :submenu=>"itemsout",
          :renewitemkeys => items.collect {|i| i.item_barcode },
          :sortby => "duedate",
          :profile => "general"
        )

      # need an extra long timeout for renewals, HIP can be slow.
      xml = get_xml_with_login(url, :timeout => @@renewal_timeout)

      # Now we need to figure out which ones were actually renewed by seeing
      # if their times renewed was incremented in the xml we got back.

      renewed = items.collect do |original_item|
          new_item = xml.at_xpath("/*/itemsoutdata/itemout[holdingkey='#{original_item.item_barcode}']")
          if new_item && (new_item.at_xpath("numrenewals/text()").to_s.to_i > original_item.times_renewed )
            original_item
          else
            nil
          end
      end.compact

      xml.xpath("/*/itemsoutdata/itemout[renewerror]").each do |item|
        errors[item.at_xpath("ikey/text()").to_s] = item.at_xpath("renewerror/text()").to_s
      end

      # Any HIP communicated overall error message?
      status_xml    = xml.at_xpath("/patronpersonalresponse/itemsoutdata/message")
      error_message = if status_xml && status_xml.at_xpath("./code/text()").to_s == "renew_failed"
        status_xml.at_xpath("./reason/text()").to_s
      end
    end

    # add in errors for any excluded_bd_items
    excluded_bd_items.each do |item|
      errors[item.item_id] = "Borrow Direct items can not be renewed."
    end

    return [renewed, errors, error_message]
  end

  # adds in session token, but does not do login or change session, neccesary
  # for submitting request to keep the same session
  def get_xml_with_current_session(url)
    url = URI.parse(url) unless url.kind_of?(URI)
    uri_query_merge(url, "GetXML" => "1", "session" => hip_session_id)

    http = HTTPClient.new
    http.receive_timeout = http.connect_timeout = @@timeout

    begin
      Rails.logger.debug("HipPilot: Reqeusting: #{url.to_s}")
      return Nokogiri::XML(http.get(url).content)

    rescue Exception => e
      Rails.logger.error("\nHipPilot: #{e.class} (#{e.message}), #{url.to_s.sub(/pin=\w+/, 'pin=[FILTERED]')} ")
      raise ConnectionError.new(e.message + ": " + url.to_s, current_user)
    end

  end

  # will request hip XML page, and check to see if there's a login prompt.
  # If not, convert to nokogiri XML. If there IS a login prompt, then
  # lookup login credentials and request again with login credentials.
  # hip_session_id will be switched if needed
  #
  # options:
  #   :timeout
  #       in seconds, override default timeout
  def get_xml_with_login(url, options = {})
    timeout = options[:timeout] || @@timeout

    url = URI.parse(url) unless url.kind_of?(URI)
    uri_query_merge(url, "GetXML" => "1", "session" => hip_session_id)

    xml = nil

    http = HTTPClient.new
    http.receive_timeout = http.connect_timeout = timeout

    if ::Rails.env == "development"
      # hip-test server has an untrusted cert, this is easiest for now.
      http.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end


    begin
      Rails.logger.debug("HipPilot: Reqeusting: #{url.to_s}")

      xml = Nokogiri::XML(http.get(url).content)



      unless xml.xpath("//exception").text().blank?
        # Sometimes HIP is weird, and we need to create a new session, not
        # sure why. Delete our stored session id, and start over.
        Rails.logger.warn("HIP exception (we will recover by creating new session): #{xml.xpath("//exception").text}")
        @rails_session.delete(:hip_session_id)
        uri_query_merge(url, "session" => nil)


        xml = Nokogiri::XML(http.get(url).content)
      end
      if (xml.xpath("//security/auth").text() != "true")
        #need to login, fix session while we're at it in case we had an
        #expired one.
        self.hip_session_id = xml.at_xpath("//session").text()

        (barcode, pin) = lookup_hip_auth

        uri_query_merge(url, "session" => self.hip_session_id, "sec1" => barcode, "sec2" => pin)


        xml = Nokogiri::XML(http.get(url).content)
        if (xml.xpath("//security/login_failed").count() != 0)
          # couldn't log in. Expired borrower account maybe?
          raise HipPilot::LoginFailure.new("Could not authenticate Horizon borrower account to system (expired or deleted borrower account? with barcode #{barcode})")
        end

      end

    rescue Exception => e
      Rails.logger.error("\nHipPilot: #{e.class} (#{e.message}), #{filter_pin(url)} ")

      if e.kind_of? HipPilot::ConnectionError
        raise e
      else # translate to a ConnectionError
        raise ConnectionError.new(e.message + ": " + filter_pin(url.to_s), current_user)
      end
    end

    return xml
  end

  # assumes there is a 'current_user' in session, gets hip barcode
  # from that, uses that to lookup pin using HIP servlet web service
  def lookup_hip_auth
    begin
      borrower = HorizonBorrowerLookup.new.lookup(:id => current_user.horizon_borrower_id )
    rescue Exception => e
      raise ConnectionError.new("HorizonBorrowerLookup for borrower_id:'#{current_user.try(:horizon_borrower_id)}' login:'#{current_user.try(:login)}': #{e.message}")
    end
    raise ConnectionError.new("No Horizon borrower found for borrower_id:'#{current_user.try(:horizon_borrower_id)}' login:'#{current_user.try(:login)}'", current_user) if borrower.nil?
    raise ConnectionError.new("No Horizon barcode and/or pin found for borrower_id:'#{current_user.try(:horizon_borrower_id)}' login:'#{current_user.try(:login)}'", current_user) if (borrower[:barcode].blank? or borrower[:pin].blank?)

    return [borrower[:barcode], borrower[:pin]]
  end

  def hip_session_id
    @rails_session[:hip_session_id]
  end

  def hip_session_id=(val)
    @rails_session[:hip_session_id] = val
  end


  def uri_query_merge(uri, hash)
    query = query_to_hash(uri.query)
    query.merge!(hash)
    uri.query = hash_to_query(query)
    return uri
  end

  def query_to_hash(query)
    hash = {}
    return hash if query.blank?

    query.split("&").each do |pair|
      (key, value) = pair.split("=")
      value = "" if value.nil?
      value = CGI.unescape(value)
      key = CGI.unescape(key)
      # handle multi-values
      if hash[key].nil?
        hash[key] = value
      elsif hash[key].kind_of?(Array)
        hash[key].push value
      else
        hash[key] = [ hash[key]].push value
      end
    end

    return hash
  end
  def hash_to_query(hash)
    # We use custom re-implementation of built in hash.to_query,
    # because we do NOT want arrays to get that [] in the output query.
    # This implementation only handles ONE level of array.
    #hash.to_query

      hash.collect do |key, value|
        unless value.kind_of?(Array)
          value.to_query(key)
        else
          # no '[]' notation please
          value.collect {|v| v.to_query(key)} * '&'
        end
      end.sort * '&'

  end

  # Tries to parse a date from a nokogiri element,
  # returns a Date, or nil if input is nil or not
  # parseable as a date.
  def safe_date_parse(nokogiri_element)
    return nil if nokogiri_element.nil?
    return nil if nokogiri_element.text().blank?
    return nil unless nokogiri_element.text() =~ %r{\d\d/\d\d/\d\d\d\d}

    begin
      Date.strptime nokogiri_element.text(), '%m/%d/%Y'
    rescue ArgumentError, TypeError
      nil
    end
  end

  # runs at_xpath, returns #text of returned element if one exists,
  # otherwise returns empty string.
  def at_xpath_text(nokogiri_element, xpath)
    element = nokogiri_element.at_xpath(xpath)
    if element
      element.text()
    else
      ""
    end
  end

  # Before logging a HIP URL that has a PIN in it, filter the PIN
  def filter_pin(url)
    url.to_s.sub(/(pin|sec2)=\w+/, '\1=[FILTERED]')
  end

  # model object used for a 'transaction', a checkout, a request etc.
  # Not all attributes are applicable to all sorts of transactions.
  #
  # on dates: We have two dates, date_initiated and date_complete,
  # which have different meanings for different transaction types.
  # date_initiated is date request made, or date item checked out.
  # date_complete is due date, or date requested item was ready.
  # date are ruby Date or Time objects, depending on if they have
  # an exact time associated.
  #
  # label is a title/author from HIP, only used in error cases because
  # normally we lookup again from solr for consistency
  class Transaction
    def initialize(hash = {})
      hash.each_pair do |key, value|
        self.send(key.to_s + "=", value)
      end
    end
    attr_accessor :label
    attr_accessor :bib_id, :item_id, :item_barcode, :date_initiated, :date_complete, :due_date, :times_renewed, :collection_str
    # for requests, mainly
    attr_accessor :queue_position, :pickup_location, :item_status
    attr_accessor :solr_document #sometimes controller sets associated SolrDocument
  end
  class ItemOut < Transaction
    def overdue?
      tz = TZInfo::Timezone.get('US/Eastern')
      offset_in_hours = tz.current_period.utc_total_offset.numerator
      offset = '%+.2d:00' % offset_in_hours
      if (date_complete.kind_of?(Time))
        time = Time.now + offset_in_hours * 60 * 60
        time > date_complete
      elsif date_complete.nil?
        false
      else
        # just a day, see if it's after that yet
        date = Time.now.utc.getlocal(offset).to_date
        date > date_complete
      end
    end
    #force number
    def times_renewed=(val)
      @times_renewed = val.to_i
    end

    # HIP pukes if you ask it to renew a Borrow Direct item created with
    # NCIP. Is this such an item? Sadly the only good way we have to identify
    # it, from what HIP gives us in the scraped renewal process, is the barcode:
    # BD items have barcodes beginning "JHU-"
    #
    # DANGEROUS. Requires "JHU-" barcode being an accurate predictor if and ONLY if
    # Borrow Direct. But what we got to work with now. Turns out that's not true,
    # multi-volume works from BD sometimes have barcodes not beginning JHU.
    # So we're also now trying to look at the collection_str, which SOMETIMES
    # we have. This is a mess.
    def borrow_direct_item?
      self.item_barcode =~ /\AJHU\-/ || self.collection_str =~ /\ABorrow ?Direct\Z/
    end

  end


  class Note
    def initialize(hash = {})
      hash.each_pair do |key, value|
        self.send(key.to_s + "=", value)
      end
    end
    attr_accessor :reason, :note, :date, :fee
  end

  class Profile
    def initialize(hash = {})
      hash.each_pair do |key, value|
        self.send(key.to_s + "=", value)
      end
    end
    attr_accessor :name, :phone, :address_array, :home_library, :card_expiration, :email
  end

  # Used for making, and discovering options for, requests.
  # We currently have HIP/Horizon set up to only allow requests on Copies,
  # not Items, so that's what this supports.
  class Request
    attr_accessor :bib_id, :item_id
    attr_accessor :pickup_location # selected CODE of desired pickup; in older HIP's this was location description instead
    attr_accessor :queue_position, :notification_method
    attr_accessor :expire_date # a Date object.
    attr_accessor :available_locations # set via HIP XML call, array of PickupLocation
    attr_accessor :comment
    attr_accessor :item_display
    # We use Horizon 'closed stack access' feature only for MSE Special
    # Collections, and had hard-coded it that way in HIP XSL.
    # Still, we pass in a string location here of where the item can be viewed,
    # if it's "closed stack access" for us that means it can only be viewed
    # in library in a special collections dept.
    attr_accessor :closed_stack_access_location

    def initialize(options = {})
      options.each_pair do |key, value|
        self.send(key.to_s + "=", value)
      end
      raise "Need to supply bib_id and item_id" unless self.bib_id && self.item_id
    end

    # ensure default, HIP really doesn't like it when this is empty.
    def notification_method
      @notification_method || "e-mail"
    end

  end

  # Has a code and a description -- although for previous
  # versions of HIP, only description was scrapable from the interface
  class PickupLocation
    attr_accessor :code, :description
    def initialize(c, d)
      if c.nil? || d.nil? || c.empty? || d.empty?
        raise ArgumentError.new("PickupLocation needs both a code and description, code:#{c}, description:#{d}")
      end

      self.code= c
      self.description = d
    end

    # To make em sortable, sort by description
    def <=>(arg)
      self.description <=> arg.description
    end
  end

  # Raised when there is a problem connecting to HIP/Horizon for patron
  # functions. Custom rescue_action_in_public may catch to provide custom
  # error message. message should be set to something you don't mind showing to the
  # public in production.
  class ConnectionError < Exception
    def initialize(msg = nil, current_user = nil)
      super(msg)
      @for_user = current_user
    end
    def for_user
      @for_user
    end
  end
  class RequestFailure < ConnectionError
  end
  # LoginFailure means we could not log in to HIP using looked up barcode/pin,
  # this usually means expired Horizon borrower account.
  class LoginFailure < ConnectionError
  end

  class HipDisabled < ConnectionError ; end

  # could not update email address.
  # _public_ displayable message can be given
  # at public_message, usually one passed on from HIP.
  class ProfileUpdateFailure < ConnectionError
    attr_accessor :public_message
    def initialize(msg = nil, pmessage = nil)
      super(msg)
      self.public_message = pmessage
    end
  end


end
