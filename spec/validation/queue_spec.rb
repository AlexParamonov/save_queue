require "spec_helper"
require "save_queue/plugins/validation/queue"

class ValidQueue < SaveQueue::ObjectQueue
  include SaveQueue::Plugins::Validation::Queue
end


describe ValidQueue do
  let(:queue) { ValidQueue.new }

  describe "invalid objects" do
    let(:invalid_objects) { [] }
    before(:each) do
      3.times do
        invalid_objects << new_velement(:valid => false)
      end

      queue.add_all invalid_objects
    end
    
    describe "save" do
      it "should not be saved" do
        invalid_objects.each{|o| o.should_not_receive(:save)}
        queue.save.should be_false
      end

      it "should set errors" do
        queue.save.should be_false
        queue.errors[:validation].should_not be_empty
      end
    end

    describe "save!" do
      it "should raise SaveQueue::FailedValidationError exception" do
        expect { queue.save! }.to raise_error(SaveQueue::FailedValidationError)
      end

      it "should set errors" do
        expect{queue.save!}.to raise_error
        queue.errors[:validation].should_not be_empty
      end
    end
  end

  describe "valid objects" do
    let(:valid_objects) { [] }
    before(:each) do
      3.times do
        valid_objects << new_velement(:valid => true)
      end

      queue.add_all valid_objects
    end

    describe "save" do
      it "should be saved" do
        valid_objects.each{|o| o.should_receive(:save).once}
        queue.save.should be_true
      end

      it "should not set errors" do
        queue.save.should be_true
        queue.errors.should be_empty
      end
    end

    describe "save!" do
      it "should not raise an exception" do
        expect { queue.save! }.to_not raise_error
      end

      it "should not set errors" do
        queue.save!
        queue.errors.should be_empty
      end
    end
  end


  #before(:each) do
  #  @invalid = new_object
  #  @invalid.stub(:valid?).and_return(false)
  #  @valid = new_object
  #  @valid.stub(:valid?).and_return(true)
  #end

  #describe SaveQueue::Plugins::Validation::Queue do
  #  before(:each) do
  #    @save_queue = SaveQueue::Plugins::Validation::Queue.new
  #  end
  #
  #  describe "#valid?" do
  #    it "should set objects_with_errors" do
  #      @save_queue.add @invalid
  #      @save_queue.add @valid
  #
  #      @save_queue.valid?.should be_false
  #
  #      @save_queue.objects_with_errors.should include @invalid
  #      @save_queue.objects_with_errors.should_not include @valid
  #    end
  #  end
  #
  #  describe "#validate!" do
  #    it "should raise FailedValidationError if failed to save objects" do
  #      @save_queue.add @invalid
  #      @save_queue.add @valid
  #
  #      expect{ @save_queue.validate! }.to raise_error SaveQueue::Plugins::Validation::FailedValidationError
  #    end
  #
  #    it "should return true if objects were valid" do
  #      @save_queue.add @valid
  #
  #      expect{ @save_queue.validate! }.to_not raise_error SaveQueue::Plugins::Validation::FailedValidationError
  #
  #      @save_queue.validate!.should be_true
  #    end
  #  end
  #end
end