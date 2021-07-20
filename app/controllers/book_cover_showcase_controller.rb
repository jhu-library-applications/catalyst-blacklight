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
            imageURL: book_cover(doc['isbn_t']),
            catalystURL: 'https://catalyst.library.jhu.edu/catalog/' + doc['id'].to_s
          }
        }.reject{|doc| doc[:imageURL].nil? }}.as_json, callback: params['callback']
      end
    end
  end

  def image
    isbns = []
    formats = []
    if params.has_key?('bib')
      @response, @document = search_service.fetch(params['bib'])
      isbns = @document['isbn_t']
    elsif params.has_key?('isbn')
      isbns = params['isbn'].split(',')
    end
    image = book_cover(isbns)
    if image.nil?
      if params.has_key?('format')
        formats = params['format'].split(',')
      end
      redirect_to icon_cover(formats)
    else
      redirect_to image
    end
  end

end