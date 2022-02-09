require 'uri'
#require_dependency 'vendor/plugins/blacklight/app/helpers/application_helper.rb'
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def url_decode(url)
    URI.decode(url)
  end
 
  # Over-ride Umlaut default
  def application_name
    "JH Libraries"
  end


  # We use to remove 'f[format][] = Online' from params, to
  # accomodate us displaying it as a checkbox in search form.
  #
  # render_hash_as_hidden_fields(  remove_facet_params(params_for_search, :format => "Online")   )
  #
  def remove_specified_facet_params(my_params, remove_facets)
    my_params = my_params.deep_dup

    remove_facets.each_pair do |facet, values|
      facet = facet.to_sym
      values = [values] unless values.kind_of?(Array)

      next unless my_params[:f].try {|h| h[facet.to_sym] }

      my_params[:f][facet.to_sym].delete_if do |v|
        values.include? v
      end
    end

    return my_params
  end

  # Like Blacklight's render_pagination_info but works with kaminari
  # returned pagination, eg ActiveRecord
  def render_kaminari_info(pageable_list, options = {})
      per_page = pageable_list.limit_value
      current_page = pageable_list.current_page
      num_pages = pageable_list.num_pages
      start = ((current_page - 1) * per_page) + 1
      total_hits = pageable_list.total_count

      start_num = format_num(start)
      end_num = format_num(start + pageable_list.length - 1)
      total_num = format_num(total_hits)

      entry_name = options[:entry_name] ||
      (pageable_list.empty? ? 'entry' : pageable_list.first.class.model_name.human)

      if num_pages < 2
        case pageable_list.length
        when 0; "No #{h(entry_name.pluralize)} found".html_safe
        when 1; "Displaying <b>1</b> #{h(entry_name)}".html_safe
        else; "Displaying <b>all #{total_num}</b> #{entry_name.pluralize}".html_safe
        end
      else
        "Displaying #{h(entry_name.pluralize)} <b>#{start_num} - #{end_num}</b> of <b>#{total_num}</b>".html_safe
      end
  end

  # A method that lets, eg, an XML view call render partial of an HTML
  # view to embed. From http://stackoverflow.com/a/5074120/307106
  # Blackligth has it's own implementation of with_format, that is used
  # by Blacklight's atom view... but BL's implementation at least in BL 3.5.0
  # is broken, we override with a working one here. In future versions of BL,
  # you may be able to delete this and go with BL's.
  def with_format(format, &block)
    old_formats = formats
    begin
      self.formats = [format]
      return block.call
    ensure
      self.formats = old_formats
    end
  end

  # helper to make bootstrap3 nav-pill <li>'s with links in them, that have
  # proper 'active' class if active.
  # http://getbootstrap.com/components/#nav-pills
  #
  # the current pill will have 'active' tag on the <li>
  #
  # html_options param will apply to <li>, not <a>.
  #
  # can pass block which will be given to `link_to` as normal.
  def bootstrap_pill_link_to(label, link_params, html_options = {})
    current = current_page?(link_params)

    link_options = {}
    link_options[:class] = "nav-link"
    if current
      link_options[:class] << " active "
    end

    content_tag(:li, html_options) do
      link_to(label, link_params, link_options)
    end
  end


  protected
  # This logic could change as BL develops, centralize it in one
  # place
  def document_to_marc(document)
    if document.respond_to?(:to_marc)
      begin
        document.to_marc
      rescue Exception => e
        logger.error(
          "Bad MARC data, #{document["id"]}: #{e.class} (#{e.message}):\n  " +
          e.backtrace[0..5].join("\n  ") + "\n\n"
        )
        return nil
      end
    else
      nil
    end
  end


  ############
  #
  #  Search type navbar selection buttons and form
  #
  ###########

  # The current 'search area' of the app as determined by current page:
  # :catalog, :reserves, :login, :user, :articles
  # we add later to :articles
  #
  # Can return nil if no recognized search area.
  def current_search_area(p = params)
    if p[:controller] == "catalog" || p[:controller] == "advanced"
      return :catalog
    elsif p[:controller] == "reserves"
      return :reserves
    elsif p[:controller] == "users"
      return :user
    elsif p[:controller] == "user_sessions"
      return :login
    else
      return nil
    end
  end

  # render a bootstrap button for our search navbar, with appropriate
  # active status. eg:
  #     <%= render_search_button("Catalog", current_search_area == :catalog,
  #            search_url_context(:controller => "catalog", :action => "index")) %>
  def render_search_button(label, active_condition, url_arg)
     link_to_unless(active_condition, label, url_arg, :class => "search-option btn btn-outline-secondary") do
        # the version when this button is 'active', just a span
        content_tag(:span, label, :class => "search-option btn active btn-primary")
      end
  end


  def search_url_context(base = {}, params = params())
    carry_over = {}
    carry_over[:q]            = params[:q] if params[:q].present?
    carry_over[:search_field] = params[:search_field] if params[:search_field].present?

    base.merge(carry_over)
  end


  def should_include_findit_url?(document:)
    return false if document.nil?
    return false if document['format'].include?('Map/Globe')
    
    true
  end
end
