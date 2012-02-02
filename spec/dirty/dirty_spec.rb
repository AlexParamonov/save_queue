require "spec_helper"
require "save_queue/plugins/dirty"

describe SaveQueue::Plugins::Dirty do
  describe "#integration" do
    it "should mix Object to object class" do
      klass = new_class
      klass.send :include, SaveQueue::Plugins::Dirty

      klass.should include SaveQueue::Plugins::Dirty::Object
    end
    describe "functional" do
      it "README example should work" do
        article = Article.new

        tag_objects = []
        3.times do
          tag = Tag.new
          tag.change_attribute :title, "new tag"
          tag.should_receive(:save).once
          tag_objects << tag
        end
        article.tags = tag_objects

        tag = Tag.new
        tag.change_attribute :title, "single tag"
        tag.should_receive(:save).once
        article.add_tag tag

        # that will save article and all tags in this article if article
        # and tags are valid, and if article.save and all tag.save returns true
        # You may also use #save! method, that will trigger save_queue.save! and
        # raise SaveQueue::FailedSaveError on fail
        article.save.should be_true
      end
    end
  end
end

require 'save_queue'
class Article
  include SaveQueue
  include SaveQueue::Plugins::Dirty

  def change_attribute attr, value
    @attributes ||= {}
    @attributes[attr] = value
    mark_as_changed # call this and object will be marked for save
  end

  def tags= tag_objects
    @tags = tag_objects
    mark_as_changed
    save_queue.add_all tag_objects
  end

  def add_tag tag
    @tags ||= []
    @tags << tag
    save_queue.add tag # or use <<, push methods
  end
end


class Tag
  include SaveQueue
  include SaveQueue::Plugins::Dirty

  def change_attribute attr, value
    @attributes ||= {}
    @attributes[attr] = value
    mark_as_changed # call this and object will be marked for save
  end
end