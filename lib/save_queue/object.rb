require 'save_queue/object_queue'

module SaveQueue
  module Object
    def self.included base
      base.class_eval do

        class<<self
          attr_reader :queue_class

          def queue_class=(klass)
            raise "Your Queue implementation: #{klass} should include Hooks module!" unless klass.include? Hooks
            @queue_class = klass
          end
        end

        def self.inherited base
          base.queue_class = self.queue_class
        end

        self.queue_class ||= ObjectQueue
      end
    end


    module RunAlwaysFirst
      # can not reilly on save! here, because client may not define it at all
      def save(*args)
        if defined?(super)
          super_result = super
          return false if false == super_result
        end

        mark_as_saved

        return false unless save_queue.save

        super_result || true
      end

      # Expect save! to raise an Exception if failed to save an object
      def save!
        super if defined?(super)
        mark_as_saved
        save_queue.save!
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
      @_save_queue = self.class.queue_class.new
    end
  end
end