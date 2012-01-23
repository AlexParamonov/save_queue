require "spec_helper"
require "save_queue/plugins/validation"

describe SaveQueue::Plugins::Validation do
  describe "#integration" do
    it "should mix Queue to object's save_queue" do
      klass = new_class
      klass.send :include, SaveQueue::Plugins::Validation

      klass.queue_class.should include SaveQueue::Plugins::Validation::Queue
    end

    it "should not change original SaveQueue::*Queue class" do
      klass = new_class
      old_queue = klass.queue_class
      klass.queue_class = Class.new(old_queue)
      
      klass.send :include, SaveQueue::Plugins::Validation
      old_queue.should_not include SaveQueue::Plugins::Validation::Queue
    end
  end

  describe "workflow" do
    let(:object) do
      klass = new_class
      klass.send :include, SaveQueue::Plugins::Validation
      klass.new
    end

    describe "#save" do
      it "should not return false if save_queue was saved" do
        object.save_queue << new_velement(:valid => true)
        object.save.should_not be_false
      end

      it "should return false if save_queue was not saved" do
        object.save_queue << new_velement(:valid => false)
        object.save.should be_false
      end
    end
  end
end