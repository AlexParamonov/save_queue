require "save_queue/version"
require "save_queue/object"
require "save_queue/exceptions"

module SaveQueue
  def self.included base
    base.send :include, SaveQueue::Object
  end
end
