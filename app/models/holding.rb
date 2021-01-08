  # A model (although NOT db persistent, not ActiveRecord) representing ILS
  # "holdings", 'copy' or 'item'.
  # Created by the DlfExpandedPassthrough::ToHoldingsExtension.
  # Consumed by the _holding.html.erb partial.
  # Other subsidiary model classes contained here too. 
  class Holding
    attr_accessor :location, :collection, :call_number, :copy_string, :notes, :status, :run_statements
    attr_accessor :id # a non-uri string id of some kind, from dlf_expanded
    attr_accessor :due_date # a Date or DateTime object.
    attr_accessor :staff_notes_html # HTML formatted notes we hide and toggle on for staff. We use for RMST/barcode. 
    attr_reader :localInfo

    special_collections_file = Rails.root + "config/special_collections.yml"
    if File.exists? special_collections_file
      @@special_collections = YAML.load_file( special_collections_file )
    else
      Rails.logger.warn("No special collections config file found at #{special_collections_file}, no special collections request button will work.")
      @@stackmap_collections = {}
    end
    
    def initialize
      @notes = [] # array of strings
      @run_statements = [] # array of Run objects. 
      @location = KeyLabel.new
      @collection = KeyLabel.new
      @status = Status.new
      @localInfo = {}
    end

    def has_children=(val)
      @has_children = val
    end
    def has_children?
      @has_children
    end
    def requestable=(val)
      @requestable = val
    end
    def requestable?
      @requestable
    end
    def special_collection?
      @@special_collections.fetch(@location.internal_code, {}).fetch('collections', []).include? @collection.internal_code
    end
    def special_collection_site
      @@special_collections.fetch(@location.internal_code, {}).fetch('library', '')
    end

    # partition run-statements by marc_type
    def run_statements_by_type
      unless @run_statements_by_type
        @run_statements_by_type = {}
        run_statements.each do |stmt|
          (@run_statements_by_type[stmt.marc_type] ||= []) << stmt
        end
      end
      return @run_statements_by_type
    end

      # internal status code; dlf_expanded controlled vocab status code; 
      # user-displyable label. Warning, only the #display_label is guaranteed
      # to be non-nil. 
      class Status
        attr_accessor :internal_code, :dlf_expanded_code, :display_label
    
        def display_label
          @display_label || @dlf_expanded_code || @internal_code
        end
        
      end
    
      # A serial "run", eg from Marc 866, 867, 868
      class Run
        attr_accessor :marc_type, :display_statement, :note
    
        # allow initialization via hash
        def initialize(hash)
          @marc_type = hash[:marc_type]
          @display_statement = hash[:display_statement]
          @note = hash[:note]
        end
      end
      
      # simple class used for holding an internal value at #internal and
      # a display label at #display_label. 
      class KeyLabel
        attr_accessor :internal_code, :display_label
      end
  end


