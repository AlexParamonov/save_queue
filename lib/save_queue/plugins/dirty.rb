require "save_queue/plugins/dirty/object"

module SaveQueue
  module Plugins
    module Dirty
      def self.included base
        base.send :include, Dirty::Object unless base.include? Dirty::Object
      end
    end
  end
end