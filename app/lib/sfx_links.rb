require 'active_support/core_ext/hash/conversions'
require 'open-uri'
require 'net/http'
require 'cgi'
require 'base64'

# This represents a hash of links from SFX from an OpenURL request
class SfxLinks
  SFX_REQUEST_OPTIONS = '&sfx.ignore_date_threshold=1&sfx.response_type=multi_obj_xml'.freeze

  attr_reader :context_object, :target_public_names, :target_urls, :target_coverage_statements

  def initialize(context_object:)
    @context_object = context_object
  end

  def links
    doc = Nokogiri::XML(sfx_xml_request)

    # Collect the URLs, public names, and coverage statements
    @target_urls = doc.xpath('//target/target_url')
    @target_public_names = doc.xpath('//target/target_public_name')
    @target_coverage_statements = doc.xpath('//coverage_statement')

    zipped_links
  end

  def sfx_url
    "#{ENV['SFX_BASE_URL']}?#{context_object_params}#{SFX_REQUEST_OPTIONS}"
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

  def zipped_links
    if !in_sfx?
      # Combine the URLs, with the names and coverage statements.
      target_urls
        .zip(target_public_names, target_coverage_statements)
        .select { |link| link if link[0].text.match(/catalyst.library/).blank? }
        .select { |link| link if link[0].text.match(/ill.library/).blank? }
        .select { |link| link if link[1].text.match(/Electronic full text not available/).blank? }
    else
      []
    end
  end

  def add_proxy_prefix(url)
    return url if url.include? ENV['EZPROXY_PREFIX']

    url.content = "#{ENV['EZPROXY_PREFIX']}#{url.text}"
    url
  end

  def in_sfx?
    target_public_names.try(:[], 0).text.match(/not available/)
  end

  def context_object_params
    context_object.kev.to_param
  end
end
