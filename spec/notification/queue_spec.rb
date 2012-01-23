require "spec_helper"
require "save_queue/plugins/notification/queue"

class NotifyQueue < SaveQueue::ObjectQueue
  include SaveQueue::Plugins::Notification::Queue
end

describe SaveQueue::Plugins::Notification::Queue do
  let(:queue) { NotifyQueue.new }

  [:add, :<<, :push].each do |method|
    describe "##{method}" do
      let(:element) { new_element }
      
      it "should notify observers about change" do
        queue.should_receive(:changed)
        queue.should_receive(:notify_observers)
        queue.send method, element
      end

      it "should notify observer, provided result of a method call and input object" do
        queue.should_receive(:changed)
        queue.should_receive(:notify_observers).with(true, element)
        queue.send method, element
      end
    end
  end
end