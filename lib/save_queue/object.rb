require "save_queue/queue"

module SaveQueue
  module Object

    module RunAlwaysFirst
      # @return [Boolean]
      def save(*args)
        # are objects in queue valid?
        return false unless valid?
        return false unless save_queue.valid?
        #return false if defined?(super) and false == super

        super_saved = true
        super_saved = super if defined?(super)
        # object is saved here
        mark_as_saved
        return (super_saved and save_queue.save)

      end
    end


    def initialize(*args)
      super if defined?(super)
      queue = Queue.new
      instance_variable_set "@_save_queue", queue

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

    private
    def mark_as_saved
      instance_variable_set "@_changed_mark", false
    end
  end
end