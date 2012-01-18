require "spec_helper"
require "save_queue/plugins/validation"

describe SaveQueue::Plugins::Validation do
  describe "#integration" do
    it "should not change original SaveQueue::*Queue class" do
      klass = new_class
      klass.queue_class = Class.new
      old_queue = klass.queue_class
      
      klass.send :include, SaveQueue::Plugins::Validation
      old_queue.should_not include SaveQueue::Plugins::Validation::Queue
    end

    it "should mix Queue to object's save_queue" do
      klass = new_class
      klass.send :include, SaveQueue::Plugins::Validation

      klass.queue_class.should include SaveQueue::Plugins::Validation::Queue
    end
  end

  describe "workflow" do
    let(:object) do
      klass = new_class
      klass.send :include, SaveQueue::Plugins::Validation
      klass.new
    end

    describe "#save" do
      context "save_queue not saved" do
        it "should return false" do
          object.save_queue << new_velement(:valid => false)
          object.save.should be_false
        end
      end

      context "save_queue saved" do
        it "should not return false" do
          object.save_queue << new_velement(:valid => true)
          object.save.should_not be_false
        end
      end
    end
  end
end