require 'multi_json'

require 'cgi'
require 'base64'
require 'openssl'
require 'uri'

require 'httpclient'
require 'httpclient/include_client'



# 
# Fetches spell suggestions from YBoss API. 
# http://developer.yahoo.com/boss/search/
#
# We're registered with account rochkind@jhu.edu . Searches are NOT free, but
# are cheap. http://developer.yahoo.com/boss/search/#pricing
# Registered to Systems credit card.
#
# Uses a class-level HTTPClient to try and re-use http connections. 
# timeout set to 0.3 seconds, YBoss should be quick!  
#
# We take the auth stuff from https://github.com/elcamino/yboss, 
# but I wasn't happy with various other parts of that code, including error
# handling, so just copy and pasted the auth stuff and modified somewhat. 
#
# Our own YBoss account credentials are set in 
# * Rails.application.config.yboss_consumer_key
# * Rails.application.config.yboss_consumer_secret
# Usually set those in:
#   ./config/initializers/yboss_auth.rb
#
# require 'yboss_spell'
# YBossSpell.new.get_suggestion("irland") # => "ireland"
class YBossSpell
  @@timeout = 0.2
  extend HTTPClient::IncludeClient
  include_http_client do |client|
    client.connect_timeout = @@timeout
    client.send_timeout    = @@timeout
    client.receive_timeout = @@timeout
  end

  # Returns nil for no suggestions. 
  # Returns a string for a suggestion. 
  #
  # Returns false if there was an error. Consumer may want to display
  # that there was an error, or hide it silently. Either way this receiver
  # will log the error. 
  def get_suggestion(query)        
    oauth = OAuth.new(:consumer_key => self.consumer_key, 
                     :consumer_secret => self.consumer_secret)            
    signed_url = oauth.sign build_query(query)

    response = http_client.get(signed_url)
    response_hash = MultiJson.decode(response.body)
            
    suggestion = get_suggestion_from_response(response_hash)

    return nil unless suggestion
    return nil if suggestion.downcase == query.downcase

    return suggestion
  rescue ::YBossSpell::Error, ::HTTPClient::TimeoutError, ::MultiJson::LoadError => e
    Rails.logger.error("YBossSpell: #{e.inspect}")    
    return false
  end

  
  # returns nil if no suggestions, raises Error if YBoss reported
  # an error, or the response hash was not as we expected
  def get_suggestion_from_response(hash)
    if (hash["bossresponse"].try{|h| h["responsecode"]} != "200")
      raise Error.new("YBoss reported failure: #{hash.inspect}")
    end
    
    spell_hash = hash["bossresponse"].try{|h| h["spelling"]}
    
    if spell_hash.blank?
      raise Error.new("YBoss response missing spelling info: #{hash.inspect}")
    end
      
    if spell_hash["count"].to_i < 1
      return nil
    end
    
    suggestion = spell_hash["results"].first["suggestion"]

    # Need to normalize it in several ways
    suggestion = extract_suggestion(suggestion)
    
    return suggestion
  end
  
  def build_query(query)
    params = {
      :format => self.format,
      :q      => pre_escape_query(query),     
    }
    
    url = self.base_uri + '?' + 
      params.find_all { |k,v| ! v.nil? }.collect { |k,v| "#{k}=#{URI.escape(v)}" }.join('&')
    
    return url
  end

  # Take care of some weird things the API does with the suggestion
  # it returns -- un-percent-encode, get rid of some spurious
  # spaces. 
  def extract_suggestion(suggestion)
    return nil unless suggestion

    # Need to un-percent-escape it turns out
    suggestion = URI.decode(suggestion)

    # Yahoo is sending back non-ascii in unknown encodings. Latin1? What
    # a mess. It's tagged UTF-8,  if it's not even valid UTF-8, just ignore it. 
    return nil unless suggestion.valid_encoding?

    # It does an annoying thing of inserting
    # spaces before phrase quotes, we'll strip out any spaces
    # immediately following a phrase quote, although this
    # may sometimes modify actual user-entered strings, if they
    # entered spaces, oh well.  
    suggestion = suggestion.gsub(/\" +/, '"')

    return suggestion
  end
  
  def consumer_key
    @consumer_key ||= Rails.application.config.yboss_consumer_key
  end
  
  def consumer_secret
    @consumer_secret ||= Rails.application.config.yboss_consumer_secret
  end
  
  def base_uri
    @base_uri ||= 'http://yboss.yahooapis.com/ysearch/spelling'
  end
  
  def format
    @format ||= 'json'
  end
  
  # Yes, experiments show we need to sort of "double escape" queries, 
  # FIRST replace all reserved characters per http://developer.yahoo.com/boss/search/boss_api_guide/reserve_chars_esc_val.html
  # with those percent combos, THEN actually URI-escape the result TOO. 
  # Yes, this is confusing and a mess, but seems to work. 
  def pre_escape_query(query)
    # have to include apostrophe in here too, even though it's NOT
    # in the docs reserved list (and does not generally require URI escaping,
    # in theory) --  still need to double escape it to avoid YBoss returning
    # &#39; in suggestions! 
    #
    # Do not need to double escape spaces even though they do need URI escaping.  
    #
    # We are telling it ONLY to escape our list of punctuation that causes
    # trouble for YBoss unless double-escaped. Which means it won't escape
    # diacritics and other non-latin. Which means the output is still UTF8,    
    # but ruby URI.escape incorrectly tags it "ascii", which causes probelms
    # later with illegal bytes -- so we need to retag as UTF-8    
    return URI.escape(query, "/?&;:@,$=%\"#*<>{}|[]^\\`()'").force_encoding("UTF-8")
  end
  
  
  # Copied from https://github.com/elcamino/yboss/blob/master/lib/yboss/oauth.rb
  #
  # But modified to work slightly different. 
  #
  # Copyright (c) 2013, Tobias Begalke (modified by Jonathan Rochkind)
  # All rights reserved.
  # 
  # Redistribution and use in source and binary forms, with or without
  # modification, are permitted provided that the following conditions are met:
  # * Redistributions of source code must retain the above copyright
  # notice, this list of conditions and the following disclaimer.
  # * Redistributions in binary form must reproduce the above copyright
  # notice, this list of conditions and the following disclaimer in the
  # documentation and/or other materials provided with the distribution.
  # * Neither the name of the author nor the names of its contributors may
  # be used to endorse or promote products derived from this software without
  # specific prior written permission.
   class OAuth
  
    attr_accessor :consumer_key, :consumer_secret, :token, :token_secret, :req_method,
    :sig_method, :oauth_version, :callback_url, :params, :req_url, :base_str
  
    def initialize(options = {})      
      @consumer_key = options[:consumer_key] || ''
      @consumer_secret = options[:consumer_secret] || ''
      @token = ''
      @token_secret = ''
      @req_method = 'GET'
      @sig_method = 'HMAC-SHA1'
      @oauth_version = '1.0'
      @callback_url = ''
    end
  
    # openssl::random_bytes returns non-word chars, which need to be removed. using alt method to get length
    # ref http://snippets.dzone.com/posts/show/491
    def nonce
      Array.new( 5 ) { rand(256) }.pack('C*').unpack('H*').first
    end
      
    def percent_encode( string )
  
      # ref http://snippets.dzone.com/posts/show/1260
      
      return URI.escape( string, Regexp.new("[^#{URI::PATTERN::UNRESERVED.gsub("'", "")}]") ).gsub('*', '%2A')
    end
  
    # @ref http://oauth.net/core/1.0/#rfc.section.9.2
    def signature
      key = percent_encode( @consumer_secret ) + '&' + percent_encode( @token_secret )
  
      # ref: http://blog.nathanielbibler.com/post/63031273/openssl-hmac-vs-ruby-hmac-benchmarks
      digest = OpenSSL::Digest::Digest.new( 'sha1' )
      hmac = OpenSSL::HMAC.digest( digest, key, @base_str )
  
      # ref http://groups.google.com/group/oauth-ruby/browse_thread/thread/9110ed8c8f3cae81
      Base64.encode64( hmac ).chomp.gsub( /\n/, '' )
    end
  
    # sort (very important as it affects the signature), concat, and percent encode
    # @ref http://oauth.net/core/1.0/#rfc.section.9.1.1
    # @ref http://oauth.net/core/1.0/#9.2.1
    # @ref http://oauth.net/core/1.0/#rfc.section.A.5.1
    def query_string
      pairs = []
      @params.sort.each { | key, val |
        pairs.push( "#{ percent_encode( key ) }=#{ percent_encode( val.to_s ) }" )
      }
      pairs.join '&'
    end
  
    # organize params & create signature
    def sign( parsed_url )
      parsed_url = parsed_url.kind_of?(URI) ? parsed_url.clone : URI.parse(parsed_url)
      
      
      @params = {
        'oauth_consumer_key' => @consumer_key,
        'oauth_nonce' => nonce,
        'oauth_signature_method' => @sig_method,
        'oauth_timestamp' => Time.now.to_i.to_s,
        'oauth_version' => @oauth_version
      }
  
      # if url has query, merge key/values into params obj overwriting defaults
      if parsed_url.query
        CGI.parse( parsed_url.query ).each do |k,v|
          if v.is_a?(Array) && v.count == 1
            @params[k] = v.first
          else
            @params[k] = v
          end
        end
        # @params.merge! CGI.parse( parsed_url.query )
      end
  
      # @ref http://oauth.net/core/1.0/#rfc.section.9.1.2
      @req_url = parsed_url.scheme + '://' + parsed_url.host + parsed_url.path
  
      # create base str. make it an object attr for ez debugging
      # ref http://oauth.net/core/1.0/#anchor14
      @base_str = [
                   @req_method,
                   percent_encode( req_url ),
  
                   # normalization is just x-www-form-urlencoded
                   percent_encode( query_string )
  
                  ].join( '&' )
  
      # add signature
      @params[ 'oauth_signature' ] = signature
  
      parsed_url.query = self.query_string
      
      return parsed_url
    end
  end
  
  class Error < StandardError ; end
  
end
