require "spec_helper"

# TODO split by Object and Queue
describe "SaveQueue usage" do
  before(:each) do
    @base = new_object
    @related_object = new_object
  end

  describe "#has_unsaved_changes?" do
    it "should return true for changed object" do
      @base.save
      @base.should_not have_unsaved_changes
      @base.mark_as_changed
      @base.should have_unsaved_changes
    end

    it "should return false for saved object" do
      @base.mark_as_changed
      @base.should have_unsaved_changes
      @base.save
      @base.should_not have_unsaved_changes
    end

    it "should return false for new object" do
      klass = Class.new
      klass.send :include, SaveQueue

      klass.new.should_not have_unsaved_changes
    end
  end

  describe "#add" do
    it "should ignore same objects in queue" do
      @base.save_queue.add @related_object
      @base.save_queue.add @related_object
      @base.save_queue.add @related_object

      @related_object.should_receive(:save).once.and_return(true)
      @base.save.should be_true
      @base.save.should be_true
    end

    it "should raise ArgumentError if object does not include SavedQueue" do
      object = new_mock_object :without_include
      object.stub_chain(:class, :include?).with(SaveQueue::Object).and_return(false)

      expect{ @base.save_queue.add object }.to raise_error ArgumentError, "#{object.inspect} does not include SaveQueue::Object"
    end

    it "should not raise ArgumentError if object includes SavedQueue" do
      object = new_mock_object :with_include
      object.stub_chain(:class, :include?).with(SaveQueue::Object).and_return(true)

      expect{ @base.save_queue.add object }.to_not raise_error ArgumentError, "#{object.inspect} does not include SaveQueue::Object"
    end
  end

  describe "#add_all" do
    it "should delegate to #add" do
      @base.save_queue.should_receive(:add).exactly(3).times
      @base.save_queue.add_all [1,2,3]
    end
  end

  describe "#save" do
    it "should raise SaveQueue::FailedSaveError if at least one object in queue is not saved" do
      @base.save_queue.add @related_object
      bad_object = new_mock_object :bad_object
      bad_object.stub(:save).and_return(false)

      @base.save_queue.add bad_object


      expect{ @base.save_queue.save }.to raise_error SaveQueue::FailedSaveError
      #, {:saved   => [@related_object],
      #                                                                            :failed  => bad_object,
      #                                                                            :pending => []}
    end

    it "should save assigned object" do
      @base.save_queue.add @related_object

      @related_object.should_receive(:save).once.and_return(true)
      @base.save.should be_true
    end

    it "only 1st save will save the queue" do
      @base.save_queue.add @related_object

      @related_object.should_receive(:save).once.and_return(true)
      @base.save.should be_true
      @base.save.should be_true
    end

    it "should not circle" do
      object = new_object

      @base.mark_as_changed

      object.save_queue.add @base
      @base.save_queue.add object

      $object_counter = mock :counter
      $object_counter.should_receive(:increment).once

      def object.save
        result = super
        $object_counter.increment

        result
      end

      $base_counter = mock :counter
      $base_counter.should_receive(:increment).once

      def @base.save
        result = super
        $base_counter.increment

        result
      end



      #object.should_receive(:save).once.and_return(true)
      #@base.should_receive(:save).once.and_return(true)
      @base.save.should be_true
    end

    it "should save only unsaved objects" do
      object = new_object

      @base.save_queue.add object
      object.save

      object.should_not_receive(:save)
      @base.save_queue.save.should be_true
    end

    it "should save and object if it had changed state" do
      object = new_object

      @base.save_queue.add object
      object.save
      object.mark_as_changed

      object.should_receive(:save).once.and_return(true)
      @base.save.should be_true
    end

    describe "multiple callers" do
      before(:each) do
        @base2 = new_object
      end

      it "should save assigned object only once" do
        object = new_object

        @base.save_queue.add object
        @base2.save_queue.add object

        $counter = mock :counter
        $counter.should_receive(:increment).once

        def object.save
          result = super
          $counter.increment

          result
        end

        #object.should_receive(:save).once.and_return(true)
        @base.save.should be_true
        @base2.save.should be_true
      end

      it "should correctly save all objects once" do

        $base_counters = []
        3.times do |index|
          object = new_object
          $base_counters[index] = mock :counter
          $base_counters[index].should_receive(:increment).once
          eval %{
            def object.save
              result = super
              $base_counters[#{index}].increment

              result
            end
          }

          @base.save_queue.add object
        end

        $base2_counters = []
        2.times do |index|
          object = new_object
          $base2_counters[index] = mock :counter
          $base2_counters[index].should_receive(:increment).once
          eval %{
            def object.save
              result = super
              $base2_counters[#{index}].increment

              result
            end
          }

          @base2.save_queue.add object
        end

        $shared_counters = []
        2.times do |index|
          object = new_object
          $shared_counters[index] = mock :counter
          $shared_counters[index].should_receive(:increment).once
          eval %{
            def object.save
              result = super
              $shared_counters[#{index}].increment

              result
            end
          }

          @base.save_queue.add object
          @base2.save_queue.add object
        end

        @base.save.should be_true
        @base2.save.should be_true
      end
    end
  end

  describe "queue changes" do
    it "should be able to change queue class before initialization" do
      klass = Class.new
      klass.send :include, SaveQueue
      object = klass.new
      object.save_queue.should be_a SaveQueue::Queue

      other = Class.new(SaveQueue::Queue)
      klass.queue_class = other
      klass.new.save_queue.should be_kind_of other

      object.class.queue_class = other
      object.save_queue.should_not be_kind_of other
      object.save_queue.should be_a SaveQueue::Queue
    end
  end

  private
  def new_mock_object name
    bad_object = mock name
    bad_object.stub_chain(:class, :include?).with(SaveQueue::Object).and_return(true)
    bad_object.stub(:save).and_return(true)
    bad_object.stub(:has_unsaved_changes?).and_return(true)

    bad_object
  end

  def new_object
    klass = Class.new
    klass.send :include, SaveQueue

    object = klass.new
    object.mark_as_changed

    object
  end
end