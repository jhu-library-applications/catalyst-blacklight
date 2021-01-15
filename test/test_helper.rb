ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'

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

  # Add more helper methods to be used by all tests here...

  def load_bib_json(bib_id)
    JSON.parse(
      File.read(
        Rails.root.join('test', 'fixtures', 'files', 'solr_documents', "#{bib_id}.json")
      )
    )
  end

  # init session
  def sign_in
    post '/login', params: {
      barcode: Rails.application.credentials.testing[:barcode],
      pin: Rails.application.credentials.testing[:pin]
    }
  end
end
