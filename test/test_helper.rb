ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require 'webmock/minitest'

# These are URLs that do not need to be mocked
WEBMOCK_ALLOW_LIST = %w[127.0.0.1 localhost googleapis.com catalyst.library.jhu.edu bdtest.relaisd2d.com solr sfx-stage.library.jhu.edu
                        sfx.library.jhu.edu jhu.stackmap.com chromedriver.storage.googleapis.com httpstat.us].freeze

WebMock.disable_net_connect!(allow: WEBMOCK_ALLOW_LIST)

SimpleCov.start do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/test/' # for minitest
end

require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here..
  def borrowers_stub
    stub_request(:get, /.*borrowers.*/).to_return(
      status: 200,
      body: File.read(Rails.root.join('test/fixtures/files/hip.xml')),
      headers: {}
    )
  end

  def holdings_stub
    stub_request(:get, %r{/.*holdings.*/}).to_return(
      status: 200,
      body: File.read(Rails.root.join('test/fixtures/files/holdings_avail.xml')),
      headers: {}
    )
  end

  def request_confirm_stub
    stub_request(:get, /.*ipac.jsp.*/).to_return(
      status: 200, body: File.read(Rails.root.join('test/fixtures/files/bib_305929_hip_request_confirm.xml')), headers: {}
    )
  end

  def load_bib_json(bib_id)
    JSON.parse(
      File.read(
        Rails.root.join('test', 'fixtures', 'files', 'solr_documents', "#{bib_id}.json")
      )
    )
  end

  def sfx_stub
    stub_request(:get, /.*sfxlcl41.*/).
      with(
        headers: {
	        'Accept'=>'*/*',
	        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
	        'Host'=>'sfx.library.jhu.edu:8000',
	        'User-Agent'=>'Ruby'
        }).
      to_return(status: 200, body: File.read(Rails.root.join('test/fixtures/files/sfxlcl41.xml')), headers: {})
  end

  # init session
  def sign_in
    borrowers_stub

    post '/login', params: {
           barcode: Rails.application.credentials.testing[:barcode],
           pin: Rails.application.credentials.testing[:pin]
         }
  end
end
