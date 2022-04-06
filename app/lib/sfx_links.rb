require 'active_support/core_ext/hash/conversions'
require 'open-uri'
require 'net/http'
require 'cgi'
require 'base64'

# This represents a hash of links from SFX from an OpenURL request
class SfxLinks
  SFX_REQUEST_OPTIONS = '&sfx.ignore_date_threshold=1&sfx.response_type=multi_obj_xml'.freeze
  SFX_BASE_URL = ENV['SFX_BASE_URL'].gsub('"', '')
  attr_reader :context_object, :targets

  def initialize(context_object:)
    @context_object = context_object
  end

  def links
    doc = Nokogiri::XML(sfx_xml_request)

   # Targets are the URLs from SFX along with their names and coverage statements. They contain
   # additional information about the target that we don't currently display. 
    doc.xpath('//target')
  end

  def sfx_url
    "#{SFX_BASE_URL}?#{context_object_params}#{SFX_REQUEST_OPTIONS}"
  end

  def sfx_xml_request
   Rails.cache.fetch(cache_id, expires_in: 24.hours) do
      Faraday.get(URI.parse(sfx_url)).body
   end
  end

  # This returns a Base64 encoded version of the context object
  def cache_id
    Base64.urlsafe_encode64(@context_object.referent.identifiers.to_s, padding: false)
  end

  def last_modified
    DateTime.current.midnight - 1.day
  end

  private

  def context_object_params
    context_object.kev.to_param
  end
end
