require "spec_helper"
require "save_queue/object"

describe SaveQueue::Object do
  let(:klass)  { new_class }
  let(:object) { klass.new }

  describe "#has_unsaved_changes?" do
    it "should return true for changed object" do
      object.mark_as_changed
      object.has_unsaved_changes?.should eq true
    end

    it "should return false for unchanged object" do
      object.mark_as_saved
      object.has_unsaved_changes?.should eq false
    end

    it "should return false for new object" do
      new_class.new.has_unsaved_changes?.should eq false
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
    it "should call #save! on queue" do
      object.save_queue.should_receive(:save!).once
      object.save!
    end

    it "should mark object as saved" do
      object.should_receive(:mark_as_saved).once
      object.save!
    end

    context "original class has #save! method defined" do
      it "should call that method" do
        object =
          Class.new do
            include SaveQueue::Object
            attr_reader :save_called
            def save!
              @save_called = true
            end
          end.new

        expect{ object.save! }.to change { object.instance_variable_get('@save_called') }.from(nil).to(true)
      end

      it "should not catch any exception from that method" do
        object = object_that_return do
          raise Exception
        end

        expect { object.save }.to raise_error(Exception)
      end
    end
  end

  describe "#save" do
    it "should mark object as saved" do
      object.should_receive(:mark_as_saved).once
      object.save
    end

    it "should save queue" do
      object.save_queue.should_receive(:save).once
      object.save
    end

    context "original class has #save method defined" do
      it "should call that method" do
        object =
          Class.new do
            include SaveQueue::Object
            attr_reader :save_called
            def save
              @save_called = true
            end
          end.new

        expect{ object.save }.to change { object.save_called }.from(nil).to(true)
      end

      context "and it return false" do
        let(:object) { object_that_return false }

        it "should return false" do
          object.save.should be_false
        end

        it "should not save queue" do
          object.save_queue.should_not_receive(:save)
          object.save
        end
      end

      context "and it return true" do
        let(:object) { object_that_return true }

        it "should return true if queue saved successfully" do
          object.save.should be_true
        end

        it "should return false if queue not saved successfully" do
          object.save_queue.stub(:save => false)
          object.save.should be_false
        end
      end

      context "and it return nil" do
        let(:object) { object_that_return nil }

        it "should return true if queue saved successfully" do
          object.save.should eq true
        end

        it "should return false if queue not saved successfully" do
          object.save_queue.stub(:save => false)
          object.save.should eq false
        end
      end

      context "and it return not a boolean value" do
        let(:object) { object_that_return "some string" }

        it "should return object#save result if queue saved successfully" do
          object.save.should == "some string"
        end

        it "should return false if queue not saved successfully" do
          object.save_queue.stub(:save => false)
          object.save.should eq false
        end
      end
    end

    
    it "should not circle" do
      other_object = new_object

      object.mark_as_changed
      other_object.mark_as_changed

      object.save_queue.add other_object
      other_object.save_queue.add object

      object.extend count_mod
      other_object.extend count_mod

      other_object.save.should be_true

      other_object.save_call_count.should == 1
            object.save_call_count.should == 1
    end

    describe "multiple queues" do
      let(:other_object) { new_object }

      it "should save queue objects only once" do
        target = new_object
        target.mark_as_changed
        target.extend count_mod

        object      .save_queue.add target
        other_object.save_queue.add target

        other_object.save.should be_true
              object.save.should be_true

        target.save_call_count.should == 1
      end
    end
  end

  describe "queue class" do
    let(:default_queue_class) { SaveQueue::ObjectQueue         }
    let(:first_queue_class)   { Class.new(default_queue_class) }
    let(:second_queue_class)  { Class.new(default_queue_class) }

    it "should map to SaveQueue::ObjectQueue by default" do
      new_class.queue_class.should == default_queue_class
    end

    describe "changing" do
      it "should be possible" do
        klass.queue_class = second_queue_class
        object.save_queue.should be_kind_of second_queue_class
      end

      it "should not affect already created queue after initialization" do
        klass.queue_class = first_queue_class
        expect { object.class.queue_class = second_queue_class }.to_not change { object.save_queue.class }
      end

      it "should check inclusion of Hooks module" do
        expect{ klass.queue_class = Class.new }.to raise_error(RuntimeError, /Hooks/)
      end
    end

    it "inclusion of SaveQueue::Object should not override settings" do
      klass.queue_class = second_queue_class
      expect { klass.send :include, SaveQueue::Object }.to_not change { klass.queue_class }
    end

    describe "inheritance" do
      let(:parent) { new_class         }
      let(:child)  { Class.new(parent) }
      before(:each) do
        parent.queue_class = first_queue_class
      end
      
      it "should inherit settings of parent class" do
        child.queue_class.should == first_queue_class
      end

      it "should not override settings of parent class" do
        expect { child.queue_class = second_queue_class }.to_not change { parent.queue_class }
      end

      it "inclusion of SaveQueue::Object should not override settings of child class" do
        child.queue_class = second_queue_class
        expect { child.send :include, SaveQueue::Object }.to_not change { child.queue_class }
      end
    end
  end

  private
  def object_that_return(value = nil, &block)
    Class.new do
      include SaveQueue::Object
      s = block_given? ? block : lambda { value }
      define_method :save, &s
    end.new
  end

  def count_mod
    Module.new do
      attr_reader :save_call_count
      def save
        @save_call_count ||= 0
        @save_call_count += 1
        super
      end
    end
  end
end