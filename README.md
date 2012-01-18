Save Queue
==========
Save Queue allows to push objects to other object's queue for delayed save.
Queue save will triggered on object#save.

Installation
------------
    gem install save_queue

Contributing
-------------
__Please help to improve this project!__

See [contributing guide](http://github.com/AlexParamonov/save_queue/blob/master/CONTRIBUTING.md) for best practices

Usage
-----

How to start:

1. include SaveQueue:

        require 'save_queue'
        class Artice
          include SaveQueue
        end

2. call \#mark_as_changed method when object gets dirty:

        class Artice
          def change_attribute attr, value
            @attributes[attr] = value
            mark_as_changed # call this and object will be marked for save
          end
        end

or implement #has_unsaved_changes? method by yourself:
If you have custom logic for marking objects dirty then you may want to override
\#has_unsaved_changes? method in you class like this:

    def has_unsaved_changes?
      dirty? # dirty is you custom method to determine has object unsaved_changes or not
    end

method \#mark_as_saved becomes useless in this case and you should mark objects by your self.


3. point save method to your save logic or dont care if you use #save already:

        class Artice
          # @return [boolean]
          def save
            write_to_db
          end
        end

4.  If you want to use validation, include SaveQueue::Plugins::Validation and implement #valid? method. You may got failed objects from #errors\[:validation] array
\#errors are empty if no errors occurs

        require 'save_queue/plugins/validation'
        class Artice
          include SaveQueue::Plugins::Validation

          # @return [boolean]
          def valid?
            true
          end
        end

5. add SaveQueue to some other classes:

        require 'save_queue'
        class Tag
          include SaveQueue
        end

        class Artice
          def tags= tag_objects
            @tags = tag_objects
            saved_queue.add_all tag_objects
          end

          def add_tag tag
            @tags ||= []
            @tags << tag
            saved_queue.add tag # or use <<, push methods
          end
        end

6. Use it:

        article = Article.new
        tag_objects = [Tag.new, Tag.new, Tag.new]
        article.tags = tag_objects
        article.add_tag Tag.new

        # that will save article and all tags in this article if article
        # and tags are valid, and if article.save and all tag.save returns true
        # You may also use #save! method, that will trigger save_queue.save! and
        # raise SaveQueue::FailedSaveError on fail
        article.save

You may call it explicitly:

    article.save_queue.save
    article.save

See test specs for more details.

7. Handle errors

  7.1. You did not include SaveQueue::Plugins::Validation:

        unless article.save # article.save_queue.errors.any? or !article.save_queue.errors.empty?
          # @option [Array<Object>] :processed
          # @option [Array<Object>] :saved
          # @option [Object]        :failed
          # @option [Array<Object>] :pending
          article.save_queue.errors[:save]
        end


        begin
          article.save!
        rescue SaveQueue::FailedSaveError => error
          # @option [Array<Object>] :processed
          # @option [Array<Object>] :saved
          # @option [Object]        :failed
          # @option [Array<Object>] :pending
          error.context

          article.save_queue.errors[:save] # also set
        end

  7.2. You've included SaveQueue::Plugins::Validation:

        # Note: queue was not saved. You dont need to do a cleanup
        unless article.save then
          failed_objects = article.errors[:validation]
        end

        begin
          article.save!
        rescue SaveQueue::FailedValidationError => error
          # [Array<Object>]
          error.failed_objects

          article.save_queue.errors[:validation] # also set
        end

You may catch both errors by

        begin
          article.save!
        rescue SaveQueue::Error
          # do something
        end


if you want not to save an object if save_queue is invalid then add this check to your save method (or any other method that you use, ex: valid?):

    def save
      return false unless save_queue.valid?
      #..
    end

or you may add it to your validation.
Note, that #valid? and #validate return true/false and #validate! raises SaveQueue::FailedValidationError exception

Requirements
------------

* hooks
* rspec2 for testing

Compatibility
-------------
tested with Ruby

* 1.8.7
* 1.9.2
* 1.9.3
* jruby
* ruby-head
* ree

see [build history](http://travis-ci.org/#!/AlexParamonov/save_queue/builds)

Copyright
---------
Copyright © 2011-2012 Alexander N Paramonov.
Released under the MIT License. See the LICENSE file for further details.
