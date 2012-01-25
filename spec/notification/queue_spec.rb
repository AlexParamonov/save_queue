require "spec_helper"
require "save_queue/plugins/notification/queue"

class QueueWithNotification < SaveQueue::ObjectQueue
  include SaveQueue::Plugins::Notification::Queue
end

describe QueueWithNotification do
  let(:queue) { QueueWithNotification.new }

  ADD_METHODS.each do |method|
    describe "##{method}" do
      let(:element) { new_element }
      
      it "should notify observers about change" do
        queue.should_receive(:changed)
        queue.should_receive(:notify_observers)
        queue.send method, element
      end

      it "should provide input params and result of ##{method} method call to observers" do
        queue.should_receive(:changed)
        queue.should_receive(:notify_observers).with(true, element)
        queue.send method, element
      end
    end
  end
end