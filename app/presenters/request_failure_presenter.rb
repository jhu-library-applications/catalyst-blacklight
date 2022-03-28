class RequestFailurePresenter
    NON_CIRC_MESSAGE = "You can't request this online; please ask library staff about a copy through other local libraries."
    NEW_NON_CIRC_MESSAGE = 'You can’t request this item. Please ask library staff about using it in the library or for help locating another copy.'.freeze

    def initialize(exception:)
        @exception = exception
    end

    def message
        return '' unless @exception.present?

        if @exception.message.include?(NON_CIRC_MESSAGE)
            NEW_NON_CIRC_MESSAGE
        else
            @exception.message
        end
    end
end
