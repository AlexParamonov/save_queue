require 'save_queue/object_queue'

module SaveQueue
  module Object
    def self.included base
      base.class_eval do

        class<<self
          attr_accessor :queue_class
        end

        def self.inherited base
          base.queue_class = self.queue_class
        end

        self.queue_class ||= ObjectQueue
      end
    end


    module RunAlwaysFirst
      # @return [Boolean]
      #def save(*args)
      #  #return false if defined?(super) and false == super
      #
      #  super_saved = super if defined?(super)
      #  # object is saved here
      #  mark_as_saved
      #
      #  save_queue.save ? (super_saved || true) : false
      #end

      # can not reilly on save! here, because client may not define it at all
      # TODO FIXME may try to save it twice if added to different objects queues and super returned false.
      def save(*args)
        super_result = true
        super_result = super if defined?(super)

        return false unless !!super_result

        mark_as_saved
        if save_queue.save
          true == super_result ? true : super_result
        else
          false
        end
      end

      # Suppose,that save! raise an Exception if failed to save an object
      def save!
        super if defined?(super)
        mark_as_saved
        save_queue.save!
      end
    end

    def initialize(*args)
      queue = self.class.queue_class.new
      instance_variable_set "@_save_queue", queue

      super if defined?(super)

      # this will make RunAlwaysFirst methods triggered first in inheritance tree
      extend RunAlwaysFirst
    end

    def mark_as_changed
      instance_variable_set "@_changed_mark", true
    end

    def has_unsaved_changes?
      status = instance_variable_get("@_changed_mark")
      status.nil? ? false : status
    end

    def save_queue
      instance_variable_get "@_save_queue"
    end

    def mark_as_saved
      instance_variable_set "@_changed_mark", false
    end
  end
end