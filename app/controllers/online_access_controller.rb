# Controller for accessing links from SFX based on a provided OpenURL
class OnlineAccessController < ApplicationController
    def show
      context_object = OpenURL::ContextObject.new_from_kev(params.to_query)
  
      @sfx_links = SfxLinks.new(context_object: context_object)
      @urls = OnlineAccessPresenter.new(urls: @sfx_links.links).overflow
  
      respond_to do |format|
        format.html { render layout: false }
      end
  
      expires_in 10.minutes
    end
  end
