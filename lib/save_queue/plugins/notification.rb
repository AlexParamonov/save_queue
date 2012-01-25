require "save_queue/plugins/notification/queue"
require "save_queue/plugins/notification/object"

module SaveQueue
  module Plugins
    module Notification
      def self.included base
        klass = Class.new(base.queue_class)
        klass.send :include, Notification::Queue  unless klass.include? Notification::Queue
        base.send  :include, Notification::Object unless base.include?  Notification::Object
        base.queue_class = klass
      end
    end
  end
end