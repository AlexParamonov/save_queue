require "spec_helper"
require "save_queue/uniq_queue"

describe SaveQueue::UniqQueue do
  let(:queue)   { SaveQueue::UniqQueue.new }
  #let(:element) { new_element(:element)    }

  [:size, :count].each do |method|
    describe "##{method}" do
      it "should return 0 for empty queue" do
        queue.send(method).should be_zero
      end

      it "should count elements in queue" do
        3.times do
          queue << new_element
        end

        queue.send(method).should == 3
      end
    end
  end

  describe "#new" do
    it "should be empty queue" do
      queue.should have(0).elements
      queue.should be_empty
    end
  end

  [:add, :<<, :push].each do |method|
    describe "##{method}" do
      let(:element) { new_element }
      it "should add object to a queue" do
        queue.should be_empty

        queue.send(method, new_element)
        queue.should_not be_empty
        queue.should have(1).elements

        queue.send(method, new_element)
        queue.should_not be_empty
        queue.should have(2).elements
      end

      it "should add object to a queue once" do
        queue.should be_empty

        queue.send(method, element)
        queue.should have(1).elements

        queue.send(method, element)
        queue.should have(1).elements
      end

      it "should return true" do
        queue.send(method, element).should === true
      end

      it "should return false if element was not added" do
        queue.send(method, element)
        queue.should have(1).elements
        
        queue.send(method, element).should === false
      end
    end
  end

  describe "#add_all" do
    it "should delegate to #add" do
      queue.should_receive(:add).exactly(3).times
      queue.add_all [1,2,3]
    end

    it "should act as #add if single argument passed" do
      queue.should_receive(:add).once
      queue.add_all 1
    end
  end


  describe "#clear" do
    it "should clear the queue" do
      fill_queue
      #expect{ queue.clear }.to change{ queue.count }.from(5).to(0)
      queue.should_not be_empty
      queue.clear
      queue.should be_empty
    end
  end

  describe "#pop" do
    it "should remove last element from queue and return it back" do
      queue << new_element(:first)
      queue << new_element
      queue << new_element
      last = new_element(:last)
      queue << last

      result = nil
      expect{ result = queue.pop }.to change{ queue.count }.by(-1)
      result.should_not be_nil
      result.should be last
    end
  end

  describe "#shift" do
    it "should remove first element from queue and return it back" do
      first = new_element(:first)
      queue << first
      queue << new_element
      queue << new_element
      queue << new_element(:last)

      result = nil
      expect{ result = queue.shift }.to change{ queue.count }.by(-1)
      result.should_not be_nil
      result.should be first
    end
  end

  describe "delegates" do
    let(:queue_var) { queue.instance_variable_get("@queue") }

    SaveQueue::UniqQueue::DELEGATED_METHODS.each do |method|
      it "##{method}\tshould delegate to @queue##{method}" do
        queue_var.should_receive(method).once
        queue.send method
      end
    end
  end
end