if RUBY_VERSION < "1.9"
  require "save_queue/ruby1.9/observer"
else
  require 'observer'
end

module SaveQueue
  module Plugins
    module Notification
      module Queue
        def self.included base
          base.send :include, Observable
          base.after_add :change_and_notify
        end

        private
        def change_and_notify(*args)
          changed
          notify_observers(*args)
        end
      end
    end
  end
end
