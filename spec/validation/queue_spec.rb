require "spec_helper"
require "save_queue/plugins/validation/queue"

class QueueWithValidation < SaveQueue::ObjectQueue
  include SaveQueue::Plugins::Validation::Queue
end


describe QueueWithValidation do
  let(:queue) { QueueWithValidation.new }

  context "is empty" do
    specify { queue.should be_valid }

    describe "#save" do
      specify { queue.save.should be_true }
    end

    describe "#save!" do
      specify { expect { queue.save! }.to_not raise_error }
    end
  end

  context "contains valid objects" do
    let(:valid_objects) do
      3.times.map do
        new_velement(:valid => true)
      end
    end

    before(:each) do
      queue.add_all valid_objects
    end

    describe "#save" do
      specify { queue.save.should be_true }
      
      it "should save all elements" do
        valid_objects.each{|o| o.should_receive(:save).once}
        queue.save.should be_true
      end
    end

    describe "#save!" do
      specify { expect { queue.save! }.to_not raise_error }
      
      it "should save all elements" do
        valid_objects.each{|o| o.should_receive(:save).once}
        queue.save!
      end
    end

    describe "#valid?" do
      specify {queue.valid?.should be_true}

      it "should not has any errors" do
        queue.valid?
        queue.errors.should be_empty
      end
    end

    describe "#validate!" do
      it "should not raise any exception" do
        expect { queue.validate! }.not_to raise_error
      end

      it "should not has any errors" do
        queue.validate!
        queue.errors.should be_empty
      end
    end
  end

  shared_context "queue with invalid objects" do
    before(:each) do
      queue.add_all objects
    end

    describe "#save" do
      specify { queue.save.should be_false }
      
      it "should not save elements" do
        objects.each{|o| o.should_not_receive(:save)}
        queue.save.should be_false
      end
    end

    describe "#save!" do
      specify { expect {queue.save!}.to raise_error(SaveQueue::FailedValidationError) }
      
      it "should not save elements" do
        objects.each do |o|
          o.as_null_object
          o.should_not_receive(:save)
        end
      end
    end

    describe "#valid?" do
      specify {queue.valid?.should be_false}

      it "should set errors" do
        queue.valid?
        queue.errors[:validation].should_not be_empty
      end
    end

    describe "#validate!" do
      it "should raise SaveQueue::FailedValidationError exception" do
        expect { queue.validate! }.to raise_error(SaveQueue::FailedValidationError)
      end

      it "should set errors" do
        expect{queue.validate!}.to raise_error
        queue.errors[:validation].should_not be_empty
      end
    end

  end

  context "contains invalid objects" do
    it_behaves_like "queue with invalid objects" do
      let(:objects) do
        3.times.map { new_velement(:valid => false) }
      end
    end
  end

  context"contains mix of valid and invalid objects" do
    it_behaves_like "queue with invalid objects" do
      let(:objects) do
        2.times.map do
          new_velement(:valid => true)
          new_velement(:valid => false)
        end
      end
    end

    it "#save should call #valid?" do
      queue.should_receive(:valid?)
      queue.save
    end

    it "#save! should call #validate!" do
      queue.should_receive(:validate!)
      queue.save!
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
  #      expect{ @save_queue.validate! }.not_to raise_error SaveQueue::Plugins::Validation::FailedValidationError
  #
  #      @save_queue.validate!.should be_true
  #    end
  #  end
  #end
end