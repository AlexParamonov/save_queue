require "spec_helper"
require "save_queue/object"

describe SaveQueue::Object do
  let(:object) { new_object }

  describe "#has_unsaved_changes?" do
    it "should return true for changed object" do
      object.mark_as_changed
      object.should have_unsaved_changes
    end

    it "should return false for unchanged object" do
      object.mark_as_saved
      object.should_not have_unsaved_changes
    end

    it "should return false for new object" do
      klass = Class.new
      klass.send :include, SaveQueue::Object

      klass.new.should_not have_unsaved_changes
    end
  end

  describe "marks" do
    it "should change state of an object" do
      object.mark_as_saved
      object.should_not have_unsaved_changes
      object.mark_as_changed
      object.should have_unsaved_changes
      object.mark_as_saved
      object.should_not have_unsaved_changes
    end
  end

  describe "#save!" do
    it "should delegate to save" do
      object.save_queue.should_receive(:save!).once
      object.save!
    end
  end

  describe "#save" do
    it "should save queue" do
      object.save_queue.should_receive(:save).once
      object.save
    end

    it "should save itself" do
      klass = Class.new do
        def save
          "saved!"
        end
      end

      klass.send :include, SaveQueue::Object
      klass.new.save.should == "saved!"
    end

    context "object could not be saved" do
      let(:object) do
        klass = Class.new do
          def save
            false
          end
        end
        klass.send :include, SaveQueue::Object
        klass.new
      end
      
      it "should return false" do
        object.save.should == false
      end

      it "should not save queue" do
        object.save_queue.should_not_receive(:save)
        object.save
      end
    end

    
    it "should not circle" do
      other_object = new_object

      object.mark_as_changed
      other_object.mark_as_changed


      object      .save_queue.add other_object
      other_object.save_queue.add object

      $object_counter = mock :counter
      $object_counter.should_receive(:increment).once

      def object.save
        result = super
        $object_counter.increment

        result
      end

      $other_object_counter = mock :counter
      $other_object_counter.should_receive(:increment).once

      def other_object.save
        result = super
        $other_object_counter.increment

        result
      end

      #object.should_receive(:save).once.and_return(true)
      #@base.should_receive(:save).once.and_return(true)
      other_object.save.should be_true
    end

    describe "multiple queues" do
      let(:other_object) { new_object }

      it "should save object only once" do
        target = new_object
        target.mark_as_changed

        object      .save_queue.add target
        other_object.save_queue.add target

        $counter = mock :counter
        $counter.should_receive(:increment).once

        def target.save
          result = super
          $counter.increment

          result
        end

        #target.should_receive(:save).once.and_return(true)
        object.save.should be_true
        other_object.save.should be_true
      end
    end
  end

  describe "queue" do

    
    it "should mapped to SaveQueue::ObjectQueue by default" do
      klass = new_class
      klass.queue_class.should be SaveQueue::ObjectQueue
    end

    describe "queue changes" do
      #let(:queue)       { Class.new }
      #let(:other_queue) { Class.new }
      #before(:each) do
      #  # set queue to default
      #  klass.queue_class = queue
      #end

      let(:queue_class)       { Class.new }
      let(:other_queue_class) { Class.new }

      it "should be able to change queue class before initialization" do
        klass = new_class
        klass.queue_class = other_queue_class
        klass.new.save_queue.should be_kind_of other_queue_class
      end

      it "should not change queue class after initialization" do
        klass = new_class
        klass.queue_class = queue_class
        object = klass.new
        
        object.save_queue.should     be_a       queue_class
        object.class.queue_class     =          other_queue_class
        object.save_queue.should_not be_kind_of other_queue_class
        object.save_queue.should     be_a       queue_class
      end
    end
        


    describe "inheritance" do
      let(:queue_class)       { Class.new }
      let(:other_queue_class) { Class.new }
      let(:klass)             { new_class }
      
      it "should inherit settings of parent class" do
        klass.queue_class = queue_class

        child = Class.new(klass)
        child.queue_class.should == queue_class
      end

      it "should not override settings of parent class" do
        klass.queue_class = queue_class

        child = Class.new(klass)
        child.queue_class = other_queue_class
        child.queue_class.should == other_queue_class

        klass.queue_class.should == queue_class
      end


      it "include SaveQueue::Object should not override settings of parent class" do
        klass.queue_class = queue_class

        child = Class.new(klass)
        child.send :include, SaveQueue::Object
        child.queue_class.should == queue_class
      end
    end
  end
end