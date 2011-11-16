require "save_queue/queue"
require 'active_support/core_ext/class/inheritable_attributes'

module SaveQueue
  module Object
    #class_inheritable_accessor :queue_class
    def self.included base
      base.class_eval do
        class_inheritable_accessor :queue_class
        #class<<self
        #  attr_accessor :queue_class
        #end

        self.queue_class ||= Queue
      end
    end

    module RunAlwaysFirst
      # @return [Boolean]
      def save(*args)
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
      queue = self.class.queue_class.new
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