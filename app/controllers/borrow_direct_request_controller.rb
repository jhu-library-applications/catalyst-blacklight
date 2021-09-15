# A controller creating request in BD.

class BorrowDirectRequestController < BorrowDirectController

  include Blacklight::Searchable

  before_action :verify_user, only: [:request_item]

  def request_options
    @response, @document = search_service.fetch(params[:id])

    if @document['isbn_t'].respond_to?('each')
      isbns = @document['isbn_t']
      query = {
        "PartnershipId": "BD",
        "ExactSearch": isbns.map{|isbn| { "Type": "ISBN", "Value": isbn }}
      }
      response = Faraday.post("https://#{ENV['RELAIS_API_URL']}/dws/item/available?aid=#{authenticate}",
                              query.to_json,
                              "Content-Type" => "application/json")
      body = JSON.parse(response.body)
      @available = body['Available']
      if @available
        @locations = body['PickupLocation']
      end
    else
      @available = false
    end

    respond_to do |format|
      format.html
      render :partial => "borrow_direct_request/request_options"
    end

  end

  def request_item

    borrower = HorizonBorrowerLookup.new.lookup(:id => current_user.horizon_borrower_id )
    barcode  = borrower[:barcode]

    @response, @document = search_service.fetch(params[:id])
    isbns = @document['isbn_t']
    query = {
      "PartnershipId": "BD",
      "ExactSearch": isbns.map{|isbn| { "Type": "ISBN", "Value": isbn }},
      "PickupLocation": params[:pickup_location]
    }

    response = Faraday.post("https://#{ENV['RELAIS_API_URL']}/dws/item/add?aid=" + authenticate,
                 query.to_json,
                 "Content-Type" => "application/json")

    body = JSON.parse(response.body)

    if body.key?('RequestNumber')
      @message = { "status": true, "RequestNumber": body['RequestNumber']}
    else
      @message = {
        "status": false ,
        "code": body['Problem']['Code'],
        "message": body['Problem']['Message']
      }
    end

    respond_to do |format|
      format.html
      render :partial => "borrow_direct_request/request_item"
    end
  end

  protected

  def authenticate(barcode = nil)
    # We are going to set a cookie once authenticated
    # If the cookie is not set yet or we have an authenticated user then we'll fetch a new user token
    if cookies[:borrow_direct].nil? || !barcode.nil?
      if barcode.nil?
        barcode = ENV["RELAIS_PATRON_ID"]
      end

      response = Faraday.post("https://#{ENV['RELAIS_API_URL']}/portal-service/user/authentication", {
        "ApiKey": ENV["RELAIS_API_KEY"],
        "UserGroup": "patron",
        "LibrarySymbol": ENV["RELAIS_LIBRARY_SYMBOL"],
        "PatronId": barcode
      }.to_json, "Content-Type" => "application/json")

      cookies[:borrow_direct] = {
        value: JSON.parse(response.body)['AuthorizationId'],
        expires: 10.minutes.from_now,
        secure: true,
        httponly: true,
      }
    end

    cookies[:borrow_direct]

  end

end
