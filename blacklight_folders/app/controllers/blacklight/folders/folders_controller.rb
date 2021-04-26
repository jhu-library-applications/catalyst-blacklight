require_dependency "blacklight/folders/application_controller"

module Blacklight::Folders
  class FoldersController < ApplicationController
    include Blacklight::TokenBasedUser
    include Blacklight::SearchContext

    load_and_authorize_resource class: Blacklight::Folders::Folder, except: [:add_bookmarks, :remove_bookmarks]
    before_action :load_and_authorize_folder, only: [:add_bookmarks, :remove_bookmarks]
    before_action :clear_session_search_params, only: [:show]

    def index
      @folders = if current_or_guest_user.new_record?
        # Just show the temporary folder
        current_or_guest_user.folders

      else
        Blacklight::Folders::Folder.accessible_by(current_ability)
      end

      if ['created_at', 'updated_at'].include?(params[:order_by])
        @folders = @folders.order(params[:order_by] + ' DESC')
      elsif ['name', 'number_of_members'].include?(params[:order_by])
        @folders = @folders.order(params[:order_by])
      end
    end

    def show
      @response = @folder.response
      respond_to do |format|
        format.html { }
        document_export_formats(format, @response)
      end
    end

    def new
    end

    def edit
    end

    def create
      @folder.user = current_user
      if @folder.save
        redirect_to @folder
      else
        render :new
      end
    end

    def update
      form = folder_form_class.new(create_params)
      if form.update(@folder)
        respond_to do |format|
          format.html do
            redirect_to @folder, notice: t(:'helpers.submit.folder.updated')
          end
          format.json do
            render json: @folder
          end
        end
      else
        render :edit
      end
    end

    def destroy
      @folder.destroy
      redirect_to main_app.root_path, notice: "Folder \"#{@folder.name}\" was successfully deleted."
    end

    def add_bookmarks
      doc_ids = Array(params['document_ids'].split(',').map(&:strip))
      @folder.add_bookmarks(doc_ids)

      if @folder.save
        message = doc_ids.size == 1 ? t(:'helpers.submit.folder.added_one', folder_name: @folder.name) : t(:'helpers.submit.folder.added_many', folder_name: @folder.name)
        redirect_to :back, notice: message
      else
        redirect_to :back, alert: 'Unable to save bookmarks.'
      end
    end

    def remove_bookmarks
      item_ids = Array(params['item_ids'].split(',').map(&:to_i))
      items = @folder.items.select {|x| item_ids.include?(x.id)}
      @folder.remove_bookmarks(items)
      redirect_to :back
    end

    protected

      def current_ability
        if token_user
          ::Ability.new(token_user)
        else
          super
        end
      end

      # These methods are extracted from Blacklight::Catalog and maybe can be extracted to a reusable model.
      def document_export_formats(format, response)
        format.any do
          format_name = params.fetch(:format, '').to_sym

          if response.export_formats.include? format_name
            render_document_export_format format_name, response
          else
            raise ActionController::UnknownFormat.new
          end
        end
      end

      ##
      # Render the document export formats for a response
      # First, try to render an appropriate template (e.g. index.endnote.erb)
      # If that fails, just concatenate the document export responses with a newline.
      def render_document_export_format format_name, response
        begin
          render
        rescue ActionView::MissingTemplate
          render text: response.documents.map { |x| x.export_as(format_name) if x.exports_as? format_name }.compact.join("\n"), layout: false
        end
      end
    protected

      def folder_form_class
        FolderForm
      end

    private

      def _prefixes
	      @_prefixes ||= super + ['catalog']
	    end

      def create_params
        params.require(:folder).permit(:name, :visibility, items_attributes: [:id, :position, :_destroy, :folder_id])
      end

      def clear_session_search_params
        # TODO: Is there a blacklight method we can use to do this?
        session['search'] = nil
      end

      def load_and_authorize_folder
        id = params['id'] || params['folder']['id']
        if id == '0' && current_or_guest_user.new_record?
          # Clear out the temporary folder
          current_or_guest_user.folders = []
          # This should be the only place a real folder is created for a guest user
          @folder = current_or_guest_user.folders.first_or_initialize(name: Folder.default_folder_name)
          # Now that the guest user needs a folder, persist the user.
          current_or_guest_user.save!
          # Reset the cached cancan ability
          @current_ability = nil
        else
          @folder = Folder.find(id)
        end
        authorize! :update_bookmarks, @folder
      end
  end
end
