require "spec_helper"
require "save_queue/plugins/notification"

describe SaveQueue::Plugins::Notification do
  describe "#integration" do
    it "should mix Queue to object's save_queue" do
      klass = new_class
      klass.send :include, SaveQueue::Plugins::Notification

      klass.queue_class.should include SaveQueue::Plugins::Notification::Queue
    end

    it "should not change original SaveQueue::*Queue class" do
      klass = new_class
      old_queue = klass.queue_class
      klass.queue_class = Class.new(old_queue)

      klass.send :include, SaveQueue::Plugins::Notification
      old_queue.should_not include SaveQueue::Plugins::Notification::Queue
    end

    it "should mix Object to object class" do
      klass = new_class
      klass.send :include, SaveQueue::Plugins::Notification

      klass.should include SaveQueue::Plugins::Notification::Object
    end
  end

  describe "workflow" do
    let(:object) do
      klass = new_class
      klass.send :include, SaveQueue::Plugins::Notification
      klass.new
    end

    ADD_METHODS.each do |method|
      it "should call queue_changed_event if save_queue was changed by ##{method} method" do
        object.should_receive(:queue_changed_event)
        object.save_queue.send method, new_object
      end
    end
  end
end