require "spec_helper"
require "save_queue/object"

describe SaveQueue::Object do
  let(:object) { new_object }

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
    context "changed object" do
      let(:changed_object) {object.mark_as_changed; object}

      it "should mark object as saved" do
        changed_object.should_receive(:mark_as_saved).once
        changed_object.save!
      end

      it "should call #save! on queue" do
        changed_object.save_queue.should_receive(:save!).once
        changed_object.save!
      end

      context "original class has #save! method defined" do
        it "should call that method" do
          changed_object =
            Class.new do
              include SaveQueue::Object
              attr_reader :save_called
              def save!
                @save_called = true
              end
            end.new

          changed_object.mark_as_changed
          expect{ changed_object.save! }.to change { changed_object.save_called }.from(nil).to(true)
        end

        it "should not catch any exception from that method" do
          changed_object =
            Class.new do
              include SaveQueue::Object

              def save!
                raise Exception
              end
            end.new

          changed_object.mark_as_changed
          expect { changed_object.save! }.to raise_error(Exception)
        end
      end
    end

    context "not changed object" do
      let(:not_changed_object) {object.mark_as_saved;   object}

      it "should not mark object as saved" do
        not_changed_object.should_not_receive(:mark_as_saved)
        not_changed_object.save!
      end

      it "should call #save! on queue" do
        not_changed_object.save_queue.should_receive(:save!).once
        not_changed_object.save!
      end

      context "original class has #save! method defined" do
        it "should not call that method" do
          not_changed_object =
            Class.new do
              include SaveQueue::Object
              attr_reader :save_called
              def save!
                @save_called = true
              end
            end.new

          not_changed_object.mark_as_saved
          expect{ not_changed_object.save! }.to_not change { not_changed_object.save_called }
        end

        context "multiple save with changing state" do
          it "should call that method if state was changed after 1st save" do
            not_changed_object =
              Class.new do
                include SaveQueue::Object
                attr_reader :save_called
                def save!
                  @save_called = true
                end
              end.new
            not_changed_object.save!
            not_changed_object.mark_as_changed
            changed_object = not_changed_object

            expect{ changed_object.save! }.to change { changed_object.save_called }.from(nil).to(true)
          end
        end
      end
    end
  end

  describe "#save" do

    context "changed object" do
      let(:changed_object) {object.mark_as_changed; object}

      it "should mark object as saved" do
        changed_object.should_receive(:mark_as_saved).once
        changed_object.save
      end

      it "should save queue" do
        changed_object.save_queue.should_receive(:save).once
        changed_object.save
      end

      context "original class has #save method defined" do
        it "should call that method (save object)" do
          changed_object =
            Class.new do
              include SaveQueue::Object
              attr_reader :save_called
              def save
                @save_called = true
              end
            end.new

          changed_object.mark_as_changed
          expect{ changed_object.save }.to change { changed_object.save_called }.from(nil).to(true)
        end

        context "and it return false" do
          let(:changed_object) { changed_object_for class_that_return(false) }

          it "should return false" do
            changed_object.save.should be_false
          end

          it "should not save queue" do
            changed_object.save_queue.should_not_receive(:save)
            changed_object.save
          end
        end

        context "and it return true" do
          let(:changed_object) { changed_object_for class_that_return(true) }

          it "should return true if queue saved successfully" do
            changed_object.save.should be_true
          end

          it "should return false if queue not saved successfully" do
            changed_object.save_queue.stub(:save => false)
            changed_object.save.should be_false
          end
        end

        context "and it return nil" do
          let(:changed_object) { changed_object_for class_that_return(nil) }

          it "should return true if queue saved successfully" do
            changed_object.save.should eq true
          end

          it "should return false if queue not saved successfully" do
            changed_object.save_queue.stub(:save => false)
            changed_object.save.should eq false
          end
        end

        context "and it return not a boolean value" do
          let(:changed_object) { changed_object_for class_that_return("some string") }

          it "should return object#save result if queue saved successfully" do
            changed_object.save.should == "some string"
          end

          it "should return false if queue not saved successfully" do
            changed_object.save_queue.stub(:save => false)
            changed_object.save.should eq false
          end
        end
      end
    end

    context "not changed object" do
      let(:not_changed_object) {object.mark_as_saved;   object}

      it "should not mark object as saved" do
        not_changed_object.should_not_receive(:mark_as_saved)
        not_changed_object.save
      end

      it "should save queue" do
        not_changed_object.save_queue.should_receive(:save).once
        not_changed_object.save
      end

      context "original class has #save method defined" do
        it "should not call that method (dont save an object)" do
          not_changed_object =
            Class.new do
              include SaveQueue::Object
              attr_reader :save_called
              def save
                @save_called = true
              end
            end.new

          not_changed_object.mark_as_saved
          expect{ not_changed_object.save }.to_not change { not_changed_object.save_called }
        end

        context "multiple save with changing state" do
          it "should call that method if state was changed after 1st save" do
            not_changed_object =
              Class.new do
                include SaveQueue::Object
                attr_reader :save_called
                def save
                  @save_called = true
                end
              end.new
            not_changed_object.save
            not_changed_object.mark_as_changed
            changed_object = not_changed_object

            expect{ changed_object.save }.to change { changed_object.save_called }.from(nil).to(true)
          end
        end
      end
    end

    it "should not circle" do
      object       = new_count_object
      other_object = new_count_object

      object.mark_as_changed
      other_object.mark_as_changed

      object.save_queue.add other_object
      other_object.save_queue.add object

      other_object.save.should be_true

      other_object.save_call_count.should == 1
            object.save_call_count.should == 1
    end

    describe "multiple queues" do
      let(:other_object) { new_object }

      it "should save object only once" do
        target_class = new_class
        target_class.send :include, Count_mod
        target = target_class.new
        target.mark_as_changed


        object      .save_queue.add target
        other_object.save_queue.add target

        other_object.save.should be_true
              object.save.should be_true

        target.save_call_count.should == 1
      end
    end
  end

  private
  def class_that_return(value = nil, &block)
    Class.new do
      include SaveQueue::Object
      s = block_given? ? block : lambda { value }
      define_method :save, &s
    end
  end

  def new_count_object
    target_class = new_class
    target_class.send :include, Count_mod
    target_class.new
  end

  module Count_mod
    attr_reader :save_call_count
    def save
      @save_call_count ||= 0
      @save_call_count += 1
    end
  end
end