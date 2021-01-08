# search_params_logic method contained. Add in as a helper at application_controller
# level, so it can over-ride things in multiple controllers (search, search history, etc)
module RenderUnstemmedConstraintHelper

  # note: trying to over-ride render_constraints_query instead ended up
  # interfering with advanced_search_controller, which sometimes doesn't call
  # super. oh well.
  def render_constraints_filters(my_params = params)
    if my_params[:unstemmed_search]
      render_constraint_element(nil, "<i>Stemming disabled</i>".html_safe, :remove => my_params.merge(:unstemmed_search => nil))
    else
      "".html_safe
    end + super(my_params)
  end

  # note bug in Adv Search Helper rails2, where adv search isn't showing up
  # in saved searches at all. oops.
  def render_search_to_s_filters(my_params)
    if my_params[:unstemmed_search]
      render_search_to_s_element(nil, "(Stemming disabled)")
    else
      "".html_safe
    end + super(my_params)
  end

end
