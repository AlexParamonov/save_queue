require 'save_queue/object/queue_class_management'

describe SaveQueue::Object::QueueClassManagement do
  let(:klass) do
    Class.new do
      extend SaveQueue::Object::QueueClassManagement
    end
  end
  let(:default_queue_class) { SaveQueue::ObjectQueue         }
  let(:first_queue_class)   { Class.new(default_queue_class) }
  let(:second_queue_class)  { Class.new(default_queue_class) }

  it "should map to SaveQueue::ObjectQueue by default" do
    klass.queue_class.should == default_queue_class
  end

  describe "changing" do
    it "should be possible" do
      klass.queue_class = second_queue_class
      klass.queue_class.should eq second_queue_class
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
    let(:parent) { klass         }
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