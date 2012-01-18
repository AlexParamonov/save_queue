require "spec_helper"
require "save_queue/object_queue"

describe SaveQueue::ObjectQueue do
  let(:queue)   { SaveQueue::ObjectQueue.new }
  let(:element) { new_element(:element)       }

  [:add, :<<, :push].each do |method|
    describe "##{method}" do
      #it "should add only objects that implement SaveQueue::Object interface" do
      it "should not accept objects that does not respond to #save" do
        element.unstub(:save)
        expect{ queue.add element }.to raise_error ArgumentError, "#{element.inspect} does not respond to #save"
      end

      it "should not accept objects that does not respond to #has_unsaved_changes?" do
        element.unstub(:has_unsaved_changes?)
        expect{ queue.add element }.to raise_error ArgumentError, "#{element.inspect} does not respond to #has_unsaved_changes?"
      end
    end
  end

  describe "#save" do
    it "should save all object in queue" do
      5.times do
        element = stub(:element)
        element.stub(:has_unsaved_changes?).and_return(true)
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

    it "should save an object if it had changed state" do
      element = new_element(:element, :changed => false, :saved => true)

      queue << element
      
      element.stub(:has_unsaved_changes?).and_return(true)

      element.should_receive(:save).once.and_return(true)
      queue.save
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
        it "should raise SaveQueue::FailedSaveError" do
          expect{  queue.save! }.to raise_error(SaveQueue::FailedSaveError) {|error| \
            error.context.should == { :processed  => @objects.values_at(:valid1, :valid2, :not_changed),
                                      :saved      => @objects.values_at(:valid1, :valid2),
                                      :failed     => @objects[:unsaved_but_changed],
                                      :pending    => @objects.values_at(:not_changed, :saved, :valid3) }
          }
        end
      end

      describe "#save" do
        it "should not raise SaveQueue::FailedSaveError and provide errors array" do
          expect{  queue.save }.to_not raise_error(SaveQueue::FailedSaveError)
          queue.save.should be_false

          queue.errors[:save].should_not be_empty
          queue.errors.should eq :save => { :processed  => @objects.values_at(:valid1, :valid2, :not_changed),
                                            :saved      => @objects.values_at(:valid1, :valid2),
                                            :failed     => @objects[:unsaved_but_changed],
                                            :pending    => @objects.values_at(:not_changed, :saved, :valid3) }
        end
      end

      it "should not return errors for successful save" do
        queue.save.should be_false

        @objects[:unsaved_but_changed].stub(:save).and_return(true)
        queue.save.should be_true
        queue.errors.should be_empty
      end
    end

  end
end