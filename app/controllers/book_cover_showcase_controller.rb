# frozen_string_literal: true
class BookCoverShowcaseController < CatalogController

  include LocalCatalogHelper
  skip_before_action :verify_authenticity_token, if: :json_request?

  def json_request?
    request.format.json?
  end

  def list
    (@response, deprecated_document_list) = search_service.search_results
    @document_list = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(deprecated_document_list, 'The @document_list instance variable is deprecated; use @response.documents instead.')
    respond_to do |format|
      format.json do
        render json: {'bookcovers': @response.docs.map{|doc|
          {
            title: doc['title_display'],
            imageURL: params.has_key?('syndetics') ? '' : book_cover(doc['isbn_t']),
            catalystURL: 'https://catalyst.library.jhu.edu/catalog/' + doc['id'].to_s,
            isbns: doc['isbn_t']
          }
        }.reject{|doc| doc[:imageURL].nil? || doc[:isbns].nil? }}.as_json, callback: params['callback']
      end
    end
  end

end