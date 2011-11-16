require "save_queue/queue"
module SaveQueue
  module Plugins
    module Validation
      class Queue < ::SaveQueue::Queue
        attr_reader :objects_with_errors

        def initialize(*args)
          @objects_with_errors = []
          super
        end

        def valid?
          @objects_with_errors = []
          @queue.each do |object|
            @objects_with_errors << object unless object.valid?
          end

          @objects_with_errors.empty?
        end

        def validate!
          raise FailedValidationError, @objects_with_errors unless valid?

          true
        end

        def errors
          @objects_with_errors.map(&:errors).reduce(:+)
        end
      end
    end
  end
end
