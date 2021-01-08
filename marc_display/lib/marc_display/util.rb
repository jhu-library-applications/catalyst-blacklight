module MarcDisplay
  class Util
    # Uses ERB::Util.html_escape, except passes nil values
    # through unscatched, still nil. For non-Rails use,
    # would need to over-ride to use something else. 
    def self.html_escape(value)
      return nil if value.nil?

      ERB::Util.html_escape(value)
    end
    class << self
      alias_method :h_esc, :html_escape
    end
  end
end
