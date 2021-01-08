class MapController < ApplicationController

  # ?collection_code=mseaadf&call_number=MS
  def index
    holding = Holding.new
    holding.collection.internal_code = params[:collection_code]
    holding.call_number              = params[:call_number]
    
    @map_info = StackmapFetcher.new(holding).fetch_map_info  

    # No layout if it's an ajax request, we want partial html snippet
    # that will be inserted into page. 
    render :layout => !request.xhr?
  end
    
end

