module SearchHelper
  include ActionView::Helpers::UrlHelper

  def advanced_search_markup(url:)
    link_to 'Advanced Search', url, class: 'advanced_search'
  end

  def advanced_search_link(params:)
    case
    when advanced_search?
      advanced_search_markup(url: params.merge(controller: 'advanced', action: 'index'))
    when quick_search?
      params[:all_fields] = params[:q]
      advanced_search_markup(url: params.merge(controller: 'advanced', action: 'index'))
    else
      advanced_search_markup(url: '/advanced')
    end
  end

  def advanced_search?
    params.try(:[], :search_field) == 'advanced'
  end

  def quick_search?
    params.try(:[], :q).present?
  end
end
