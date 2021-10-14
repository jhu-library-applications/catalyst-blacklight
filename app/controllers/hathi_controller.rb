require 'open-uri'
require 'json'

class HathiController < ApplicationController
  attr_accessor :available, :record_url, :titles, :hathi_json

  HATHI_ROOT_URL = 'https://catalog.hathitrust.org/api/volumes/brief/'.freeze

  def index
    if session[:session_id].present?
      @hathi_json = URI.parse("#{HATHI_ROOT_URL}/oclc/#{params[:oclcnum]}.json").read
      render json: JSON.parse(@hathi_json)
    else
      raise StandardError, 'This resource cannot be accessed directly.'
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :forbidden
  end
end
