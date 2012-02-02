require 'save_queue/object_queue'
require 'save_queue/object/queue_class_management'

module SaveQueue
  module Object
    attr_reader :processed

    def self.included base
      base.send :extend, QueueClassManagement
    end

    module RunAlwaysFirst
      # can not reilly on save! here, because client may not define it at all
      def save(*args)
        no_recursion do
          if has_unsaved_changes?
            if defined?(super)
              super_result = super
              return false if false == super_result
            end
            mark_as_saved
          end

          return false unless save_queue.save

          super_result || true
        end
      end

      # TODO squash with save method
      # Expect save! to raise an Exception if failed to save an object
      def save!
        no_recursion do
          if has_unsaved_changes?
            super if defined?(super)
            mark_as_saved
          end

          save_queue.save!
        end
      end

      private
      def no_recursion
        return true if @saving
        @saving = true
        yield
      ensure
        @saving = false
      end
    end

    def initialize(*args)
      create_queue
      super if defined?(super)

      # this will make RunAlwaysFirst methods triggered first in inheritance tree
      extend RunAlwaysFirst
    end

    def mark_as_changed
      @_changed_mark = true
    end

    # @returns [Boolean] true if object has been modified
    def has_unsaved_changes?
      @_changed_mark ||= false
    end

    def save_queue
      @_save_queue
    end

    def mark_as_saved
      @_changed_mark = false
    end

    private
    def create_queue
      # queue_class located in QueueClassManagement
      @_save_queue = self.class.queue_class.new
    end
  end
end