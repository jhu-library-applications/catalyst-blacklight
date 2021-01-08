class ReservesController < CatalogController
  DefaultPerPage = 50
  DefaultSort = "title_sort asc, pub_date_sort desc"

  self.blacklight_config.sort_fields.delete_if {|key, config| config.label == "relevance"}

  # Avoid BL7 /track method on link_to_document
  self.blacklight_config.track_search_session = false

  def initialize
    super

    # set ivars that our custom _sort_and_per_page
    # will use for defaults.
    @default_per_page = DefaultPerPage
    @default_sort = DefaultSort
  end


  def index
    @per_page = 20

    query = params[:q] || params[:term] # term is used by jquery-ui autocomplete


    @courses =
      ReservesCourse.includes(:instructors).
        page(params[:page] || 1).per(params[:per_page] || 100).order("name")
    if query
      @courses = @courses.joins('LEFT OUTER JOIN reserves_course_instructors ON reserves_courses.course_id=reserves_course_instructors.reserves_course_id').where(["name like ? OR reserves_course_instructors.instructor_str like ?", "#{query}%", "#{query}%"])
    end
    if params[:location]
      @courses = @courses.where(:location_code => params[:location])
    end

    @locations = ReservesCourse.select("distinct location_code, location").order("location")

    respond_to do |format|
      format.html
      format.json do
        json = @courses.collect do |course|
          {
            :label => course.name,
            :location => course.location,
            :url => url_for(:action => "show", :id => course.course_id),
            :instructors => course.instructors.collect {|i| i.instructor_str}
          }
        end.to_json
        render :json => json
      end
    end

  end

  def show
    @course = ReservesCourse.includes(:bib_ids).find(params[:id])

    @bib_ids                  =  @course.bib_ids
    solr_ids                  = @bib_ids.collect {|j| "bib_" + j.bib_id.to_s}

    # @TODO - restore sort
    cat = Blacklight::SearchService.new(
      config: CatalogController.blacklight_config
    )

    @response, @document_list = cat.fetch(solr_ids, jh_reserves_default_sorting_paging(params.slice(:per_page, :page, :sort)))

    # @response, @document_list = search_results(params.slice(:per_page, :page, :sort)) do |search_builder|
    #  search_builder.
    #    where(blacklight_config.document_model.unique_key => solr_ids).
    #    append(:jh_reserves_default_sorting_paging)
    # end

  rescue ActiveRecord::RecordNotFound
    render :text => "Sorry, reserves section not found. You may have bookmarked a section which is no longer on reserve.", :layout => true, :status => 404
  end

  private

  # Reserves has different default per-page and sort, this Solr filter
  # method can be used in reserves to swap those in.
  def jh_reserves_default_sorting_paging(solr_params)
    per_page = (solr_params[:per_page]  || ReservesController::DefaultPerPage).to_i
    page     = (solr_params[:page] || 1).to_i
    solr_params[:rows] = per_page

    # Fix start for our actual per-page
    solr_params[:start] = per_page * (page - 1)

    solr_params[:sort] = ReservesController::DefaultSort  unless solr_params[:sort]
    solr_params
  end

  protected

  # Over-ride Blacklight method, to make sure links to documents in our
  # lists of docs in a reserves section -> still go to CatalogController,
  # not use logic in BL to keep them pointed at the current controller's #show
  # action, which would be wrong.
  # https://github.com/projectblacklight/blacklight/commit/28759058025deaab930f134143241bb69ab673d7
  def url_for_document doc
    doc
  end
  helper_method :url_for_document

  # Override Blacklight, the default for Reserves is hard-coded to 'title', thanks
  # Need to define this helper here, putting it in a Helper module it sometimes
  # gets loaded in all controllers, not just this one as an override, as we want.
  def default_sort_field
    blacklight_config.sort_fields.values.find {|d| d.label == "title"} ||  super
  end
  helper_method :default_sort_field


end
