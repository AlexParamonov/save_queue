require "spec_helper"
require "save_queue/object"

describe SaveQueue do
  describe "#include" do
    it "should include SaveQueue::Object" do
      klass = Class.new
      klass.send :include, SaveQueue

      klass.should include SaveQueue::Object
    end
  end
end