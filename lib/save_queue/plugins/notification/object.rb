module SaveQueue
  module Plugins
    module Notification
      module Object
        def self.included(base)
          base.send :include, AddObserverToQueue unless base.include?(AddObserverToQueue)
        end

        def queue_changed_event(result, object)
          mark_as_changed if result
        end

        module AddObserverToQueue
          def create_queue
            super

            queue = instance_variable_get("@_save_queue")
            raise "save queue should respond to add_observer in order to work correctly" unless queue.respond_to? :add_observer
            queue.add_observer(self, :queue_changed_event)
          end
        end
      end
    end
  end
end
