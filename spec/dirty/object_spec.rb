require "spec_helper"
require "save_queue/plugins/dirty/object"

class DirtyObject
  include SaveQueue
  include SaveQueue::Plugins::Dirty::Object
end

describe SaveQueue::Plugins::Dirty::Object do
  let(:object) { DirtyObject.new }

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
      object.has_unsaved_changes?.should eq false
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

      it "should call #save! on queue" do
        changed_object.save_queue.should_receive(:save!).once
        changed_object.save!
      end

      it "should mark object as saved" do
        changed_object.should_receive(:mark_as_saved).once
        changed_object.save!
      end

      context "original class has #save! method defined" do
        it "should call that method" do
          changed_object =
            Class.new(DirtyObject) do
              attr_reader :save_called
              def save!
                @save_called = true
              end
            end.new

          changed_object.mark_as_changed
          expect{ changed_object.save! }.to change { changed_object.save_called }.from(nil).to(true)
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
            Class.new(DirtyObject) do
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
              Class.new(DirtyObject) do
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

      it "should save queue" do
        changed_object.save_queue.should_receive(:save).once
        changed_object.save
      end

      context "original class has #save method defined" do
        it "should call that method (save object)" do
          changed_object =
            Class.new(DirtyObject) do
              attr_reader :save_called
              def save
                @save_called = true
              end
            end.new

          changed_object.mark_as_changed
          expect{ changed_object.save }.to change { changed_object.save_called }.from(nil).to(true)
        end

        #it "should save object only once in multiple queues" do
        #  other_object = new_object
        #  target = new_count_object
        #
        #  object      .save_queue.add target
        #  other_object.save_queue.add target
        #
        #  other_object.save.should be_true
        #        object.save.should be_true
        #
        #  target.save_call_count.should == 1
        #end
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
            Class.new(DirtyObject) do
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
              Class.new(DirtyObject) do
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
  end

  private
  def object_that_return(value = nil, &block)
    Class.new do
      include SaveQueue::Object
      s = block_given? ? block : lambda { value }
      define_method :save, &s
    end.new
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