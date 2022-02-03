# Controller for accessing links from SFX based on a provided OpenURL
class OnlineAccessController < ApplicationController
    rescue_from StandardError, with: :render_error

    def show
      context_object = OpenURL::ContextObject.new_from_kev(params.to_query)
  
      @sfx_links = SfxLinks.new(context_object: context_object)
      @urls = OnlineAccessPresenter.new(targets: @sfx_links.links).overflow
  
      respond_to do |format|
        format.html { render layout: false }
      end
  
      expires_in 10.minutes
    end

    def findit_url
      "https://findit.library.jhu.edu/resolve?" + OpenURL::ContextObject.new_from_kev(params.to_query).kev
    end

    def render_error
      render html: "<a>An error has occured when accessing Find It. Click <a href='#{findit_url}'>here to check Find It directly</a>.".html_safe, status: 500
    end
  end
