module SaveQueue
  class FailedValidationError < Error
    attr_reader :failed_objects
    
    def initialize(failed_objects)
      @failed_objects = Array(failed_objects)
    end


    # Overwrite to your needs
    def to_s
      "#{super}: " + @failed_objects.join("\n")
    end

    # danger if object not respond to errors or full_messages
    #def to_s
    #  "#{super}: " + @failed_objects.map{|object| "\"#{object.to_s}\": " + object.errors.full_messages.join(', ')}.join("\n")
    #end
  end
end