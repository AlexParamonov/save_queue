module SaveQueue
  class FailedValidationError < Error
    attr_reader :failed_objects
    def initialize(failed_objects)
      @failed_objects = Array(failed_objects)
    end

    def to_s # Some default way to display errors
      "#{super}: " + @failed_objects.map{|object| "\"#{object.to_s}\": " + object.errors.full_messages.join(', ')}.join("\n")
    end
  end
end