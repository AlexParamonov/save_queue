require 'hooks'
require 'save_queue/object_queue'

module SaveQueue
  module Object
    module QueueClassManagement
      def queue_class
        @queue_class ||= ObjectQueue
      end

      def queue_class=(klass)
        raise "Your Queue implementation: #{klass} should include Hooks module!" unless klass.include? Hooks
        @queue_class = klass
      end

      def inherited base
        base.queue_class = self.queue_class
      end
    end
  end
end
