require "save_queue/plugins/validation/queue"
require "save_queue/plugins/validation/exceptions"


module SaveQueue
  module Plugins
    module Validation
      def self.included base
        klass = Class.new(base.queue_class)
        klass.send :include, Validation::Queue unless klass.include? Validation::Queue
        base.queue_class = klass
      end
    end
  end
end