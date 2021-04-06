module SearchHelper
  include ActionView::Helpers::UrlHelper

  ##
  # Return a label for the currently selected search field.
  # This overrides the default blacklight helper, which
  # removes the label if it is the default search field.
  #
  # See LAG-4069 for the reasoning behind this change.
  # Overrides:
  # https://github.com/projectblacklight/blacklight/blob/bb769cdd4f1b7373a0797c731ae2949bf051e86f/app/helpers/blacklight/configuration_helper_behavior.rb#L53
  def constraint_query_label(localized_params = params)
    if !label_for_search_field(localized_params[:search_field]).present?
      'Any Field' # Force a label for the default search field
    else
      label_for_search_field(localized_params[:search_field])
    end
  end

  def advanced_search_markup(url:)
    link_to 'Advanced Search', url, class: 'advanced_search'
  end

  def advanced_search_link(params:)
    case
    when quick_search? && params.try(:[], :search_field) == 'all_fields'
      params[:all_fields] = params[:q]
      advanced_search_markup(url: params.merge(controller: 'advanced', action: 'index'))
    when advanced_search? || quick_search?
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
