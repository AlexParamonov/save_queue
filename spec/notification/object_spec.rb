require "spec_helper"
require "save_queue/plugins/notification/object"

class NotifyObject
  include SaveQueue
  include SaveQueue::Plugins::Notification::Object
end

describe SaveQueue::Plugins::Notification::Object do

  it "should register observer on queue to #queue_changed_event method" do
    NotifyObject.queue_class.any_instance.should_receive(:add_observer).with do |observer, method|
      observer.is_a?(NotifyObject) and method == :queue_changed_event
    end
    NotifyObject.new
  end

  let(:queue) do
    queue_class = Class.new
    queue_class.stub(:include?).with(Hooks).and_return(true)

    queue_class
  end
  
  it "should raise an exception if queue does not respond to #add_observer" do
    queue.any_instance.stub(:respond_to?).with(:add_observer).and_return(false)
    NotifyObject.queue_class = queue
    expect { NotifyObject.new }.to raise_error(RuntimeError, /add_observer/)
  end

  it "should not raise an exception if queue respond to #add_observer" do
    queue.any_instance.stub(:respond_to?).with(:add_observer).and_return(true)
    queue.any_instance.stub(:add_observer)
    NotifyObject.queue_class = queue
    expect { NotifyObject.new }.to_not raise_error
  end
end