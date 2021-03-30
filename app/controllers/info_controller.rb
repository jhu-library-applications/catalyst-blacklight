class InfoController < ApplicationController
  layout :determine_layout

  # not actually used at present
  def item_status
    @status_description = IlsStatus.find_by_id(params[:id])
  end

  def unstemmed_desc
    # fall through to view
  end
  
  def links
    #fall through to view
  end
  
  def libraries
    render "partial_wrapper", :locals => {:partial => "libraries"}
  end
  
  def research_links
    render "partial_wrapper", :locals => {:partial => "research_links"}
  end
  
  def useful_links
  end
  
  def credits
  end

  def determine_layout
    return false if request.xhr?
    action_name == super
  end
  
end
