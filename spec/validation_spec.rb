require "spec_helper"
require "save_queue/plugins/validation"

describe SaveQueue::Plugins::Validation do
  before(:each) do
    @invalid = new_object
    @invalid.stub(:valid?).and_return(false)
    @valid = new_object
    @valid.stub(:valid?).and_return(true)
  end

  describe SaveQueue::Plugins::Validation::Object do
    before(:each) do
      @base = new_object
    end

    context "valid object and caller" do
      before(:each) do
        @base.save_queue.add @valid
        @base.stub(:valid?).and_return(true)
      end

      it "should save caller" do
        @base.save.should be_true
      end

      it "should save queue" do
        @valid.should_receive(:save)

        @base.save
      end
    end

    context "invalid caller" do
      it "should not save queue" do
        @base.save_queue.add @valid

        @base.stub(:valid?).and_return(false)

        @valid.should_not_receive(:save)
        @base.save.should be_false
      end
    end

    context "invalid object in queue" do
      before(:each) do
        @base.save_queue.add @valid
        @base.save_queue.add @invalid
      end

      it "should not save caller" do
        @base.save.should be_false
      end

      it "should not save queue" do
        @invalid.should_not_receive(:save)
        @valid.should_not_receive(:save)

        @base.save
      end
    end
  end

  describe SaveQueue::Plugins::Validation::Queue do
    before(:each) do
      @save_queue = SaveQueue::Plugins::Validation::Queue.new
    end

    describe "#valid?" do
      it "should set objects_with_errors" do
        @save_queue.add @invalid
        @save_queue.add @valid

        @save_queue.valid?.should be_false

        @save_queue.objects_with_errors.should include @invalid
        @save_queue.objects_with_errors.should_not include @valid
      end
    end

    describe "#validate!" do
      it "should raise FailedValidationError if failed to save objects" do
        @save_queue.add @invalid
        @save_queue.add @valid

        expect{ @save_queue.validate! }.to raise_error SaveQueue::Plugins::Validation::FailedValidationError
      end

      it "should return true if objects were valid" do
        @save_queue.add @valid

        expect{ @save_queue.validate! }.to_not raise_error SaveQueue::Plugins::Validation::FailedValidationError

        @save_queue.validate!.should be_true
      end
    end
  end

  describe "#integration" do
    before(:each) do
      @klass = Class.new
      @klass.send :include, SaveQueue
      @klass.send :include, SaveQueue::Plugins::Validation
    end
    it "should set query_class to SaveQueue::Plugins::Validation::Queue" do
      @klass.queue_class.should == SaveQueue::Plugins::Validation::Queue
    end

    it "should mix SaveQueue::Plugins::Validation::Object" do
      @klass.should include SaveQueue::Plugins::Validation::Object
    end
  end

  private
  def new_object
    klass = Class.new
    klass.send :include, SaveQueue
    klass.send :include, SaveQueue::Plugins::Validation

    object = klass.new
    object.stub(:valid?).and_return(true)
    object.mark_as_changed

    object
  end
end