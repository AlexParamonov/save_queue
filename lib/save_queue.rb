require "save_queue/version"
#require "save_queue/object"

module SaveQueue
  def self.included base
    base.send :include, SaveQueue::Object
  end
end
