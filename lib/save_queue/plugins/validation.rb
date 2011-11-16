require "save_queue/queue"

require "save_queue/plugins/validation/object"
require "save_queue/plugins/validation/queue"


module SaveQueue
  module Plugins
    module Validation
      def self.included base
        # must be included after SaveQueue::Object
        base.send :include, Validation::Object
        base.queue_class = Validation::Queue
      end

      class FailedValidationError < RuntimeError
        attr_reader :failed_objects
        def initialize(failed_objects)
          @failed_objects = Array(failed_objects)
        end

        def to_s # Some default way to display errors
          "#{super}: " + @failed_objects.map{|object| "\"#{object.to_s}\": " + object.errors.full_messages.join(', ')}.join("\n")
        end
      end
    end
  end
end