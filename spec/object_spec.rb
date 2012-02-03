require "spec_helper"
require "save_queue/object"

describe SaveQueue::Object do
  let(:object) { new_object }

  describe "#save!" do
    context "object" do
      it "should call #save! on queue" do
        object.save_queue.should_receive(:save!).once
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

          expect{ object.save! }.to change { object.save_called }.from(nil).to(true)
        end

        #it "call #save! 5 time in a row should call super#save! 5 times" do
        #  object = new_count_object
        #  expect do
        #    5.times { object.save }
        #  end.to change { object.save_call_count }.from(0).to(5)
        #end

        context "and it raises an Exception" do
          let(:object) do
            Class.new do
              include SaveQueue::Object
              def save!
                raise RuntimeError
              end
            end.new
          end

          it "should raise an Exception" do
            expect{ object.save! }.to raise_error(RuntimeError)
          end

          it "should not save queue" do
            object.save_queue.should_not_receive(:save)
            object.save! rescue nil
          end
        end
      end
    end

    #it "should not circle" do
    #  object       = new_count_object
    #  other_object = new_count_object
    #
    #  object.save_queue.add other_object
    #  other_object.save_queue.add object
    #
    #  other_object.save.should be_true
    #
    #  other_object.save_call_count.should == 1
    #        object.save_call_count.should == 1
    #end

  end

  describe "#save" do

    context "object" do
      it "should save queue" do
        object.save_queue.should_receive(:save).once
        object.save
      end

      context "original class has #save method defined" do
        it "should call that method (save object)" do
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

        it "call #save 5 time in a row should call super#save 5 times" do
          object = new_count_object

          expect do
            5.times { object.save }
          end.to change { object.save_call_count }.from(0).to(5)
        end

        context "and it return false" do
          let(:object) { object_that_return(false) }

          it "should return false" do
            object.save.should be_false
          end

          it "should not save queue" do
            object.save_queue.should_not_receive(:save)
            object.save
          end
        end

        context "and it return true" do
          let(:object) { object_that_return(true) }

          it "should return true if queue saved successfully" do
            object.save.should be_true
          end

          it "should return false if queue not saved successfully" do
            object.save_queue.stub(:save => false)
            object.save.should be_false
          end
        end

        context "and it return nil" do
          let(:object) { object_that_return(nil) }

          it "should return true if queue saved successfully" do
            object.save.should eq true
          end

          it "should return false if queue not saved successfully" do
            object.save_queue.stub(:save => false)
            object.save.should eq false
          end
        end

        context "and it return not a boolean value" do
          let(:object) { object_that_return("some string") }

          it "should return object#save result if queue saved successfully" do
            object.save.should == "some string"
          end

          it "should return false if queue not saved successfully" do
            object.save_queue.stub(:save => false)
            object.save.should eq false
          end
        end
      end
    end

    it "should not circle" do
      object       = new_count_object
      other_object = new_count_object

      object.save_queue.add other_object
      other_object.save_queue.add object

      other_object.save.should be_true

      other_object.save_call_count.should == 1
            object.save_call_count.should == 1
    end
  end
end