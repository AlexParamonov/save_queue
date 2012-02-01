require "spec_helper"
require "save_queue/object_queue"

describe SaveQueue::ObjectQueue do
  let(:queue)   { SaveQueue::ObjectQueue.new }
  let(:element) { new_element(:element)       }

  ADD_METHODS.each do |method|
    describe "##{method}" do
      #it "should add only objects that implement SaveQueue::Object interface" do
      it "should accept objects that respond to #save and #has_unsaved_changes?" do
        element = stub(:element, :save => true, :has_unsaved_changes? => true)
        expect{ queue.send method, element }.not_to raise_error
      end

      it "should not accept objects that does not respond to #save" do
        element.unstub(:save)
        expect{ queue.send method, element }.to raise_error ArgumentError, "#{element.inspect} does not respond to #save"
      end

      it "should not accept objects that does not respond to #has_unsaved_changes?" do
        element.unstub(:has_unsaved_changes?)
        expect{ queue.send method, element }.to raise_error ArgumentError, "#{element.inspect} does not respond to #has_unsaved_changes?"
      end
    end
  end

  describe "#save" do
    it "should save all object in queue" do
      5.times do
        element = stub(:element, :has_unsaved_changes? => true)
        element.should_receive(:save).once
        queue << element
      end

      queue.save
    end

    it "should save an object if it has unsaved changes" do
      element = stub(:element)
      element.stub(:has_unsaved_changes?).and_return(true)
      element.should_receive(:save).once

      queue << element
      queue.save
    end

    it "should not save an object if it has not been changed" do
      element = stub(:element)
      element.stub(:has_unsaved_changes?).and_return(false)
      element.should_not_receive(:save)

      queue << element
      queue.save
    end

    it "should save an object if it has changed state after been added to a queue" do
      element = new_element(:element, :changed => false, :saved => true)

      queue << element
      
      element.stub(:has_unsaved_changes?).and_return(true)

      element.should_receive(:save).once.and_return(true)
      queue.save
    end

    it "should fail if element#save returns boolean false" do
      element = new_element
      element.stub(:save).and_return(false)
      queue << element
      queue.save.should be_false
    end

    it "should not fail if element#save returns other than boolean false" do
      ["", 0, nil, "string", true, Class.new].each do |value|
        element = new_element
        element.stub(:save).and_return(value)
        queue << element
      end

      queue.save.should be_true
    end

    it "should clear itself if saved successfully" do
      #queue.should_receive(:clear).once
      queue.save.should be_true
      queue.should be_empty
    end
  end

  context "at least one object in queue was not saved" do
    before(:each) do
      @objects ={}
      queue << @objects[:valid1]               = new_element(:valid1)
      queue << @objects[:valid2]               = new_element(:valid2)
      queue << @objects[:not_changed]          = new_element(:not_changed,         :changed => false, :saved => true)
      queue << @objects[:unsaved_but_changed]  = new_element(:unsaved_but_changed, :changed => true,  :saved => false)
      queue << @objects[:saved]                = new_element(:saved,               :changed => true,  :saved => true)
      queue << @objects[:valid3]               = new_element(:valid3)
    end

    describe "#save!" do
      it "should set errors" do
        queue.save! rescue nil

        queue.errors[:save].should_not be_empty
        queue.errors.should eq :save => { :processed  => @objects.values_at(:valid1, :valid2, :not_changed),
                                          :saved      => @objects.values_at(:valid1, :valid2),
                                          :failed     => @objects[:unsaved_but_changed],
                                          :pending    => @objects.values_at(:not_changed, :saved, :valid3) }
      end
      
      it "should raise SaveQueue::FailedSaveError" do
        expect{  queue.save! }.to raise_error(SaveQueue::FailedSaveError) {|error| \
          error.context.should == { :processed  => @objects.values_at(:valid1, :valid2, :not_changed),
                                    :saved      => @objects.values_at(:valid1, :valid2),
                                    :failed     => @objects[:unsaved_but_changed],
                                    :pending    => @objects.values_at(:not_changed, :saved, :valid3) }
        }
      end

      # TODO remove duplication
      it "should not clear queue" do
        queue.should_not_receive(:clear)
        queue.save! rescue nil
      end

      it "should not remove/add elements from/to queue" do
        expect { queue.save! rescue nil }.to_not change { queue.size }.to raise_error
      end
    end

    describe "#save" do
      it "should return false" do
        queue.save.should be_false
      end

      it "should set errors" do
        queue.save

        queue.errors[:save].should_not be_empty
        queue.errors.should eq :save => { :processed  => @objects.values_at(:valid1, :valid2, :not_changed),
                                          :saved      => @objects.values_at(:valid1, :valid2),
                                          :failed     => @objects[:unsaved_but_changed],
                                          :pending    => @objects.values_at(:not_changed, :saved, :valid3) }
      end
      
      it "should not raise SaveQueue::FailedSaveError" do
        expect{  queue.save }.not_to raise_error(SaveQueue::FailedSaveError)
      end

      it "should not clear queue" do
        queue.should_not_receive(:clear)
        queue.save
      end

      it "should not remove/add elements from/to queue" do
        expect { queue.save }.to_not change { queue.size }
      end
    end

    context "after fixing all failed objects" do
      before(:each) do
        queue.save.should be_false
        @objects[:unsaved_but_changed].stub(:save).and_return(true)
      end

      it "should save all pending objects" do
        @objects.values_at(:saved, :valid3).each do |object|
          object.should_receive(:save).once
        end

        queue.save.should be_true
      end

      it "should not save already saved objects" do
        pending "rewrite this test as integration"
        @objects.values_at(:valid1, :valid2, :not_changed).each do |object|
          object.should_not_receive(:save)
        end

        queue.save.should be_true
      end

      it "should not have any errors" do
        queue.save
        queue.errors.should be_empty
      end
    end
  end
end