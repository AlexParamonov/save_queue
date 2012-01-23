Save Queue
==========
Save Queue allows to push objects to other object's queue for a delayed save.
Queue save will be triggered by object#save.


Contents
---------
1. Installation
1. Contributing
1. Usage
    * Getting started
    * Tracking changes
    * Error handling
1. Plugins
    * Validation
    * Notification
1. Creating your own Queues / TODO
1. FAQ
1. Requirements
1. Compatibility
1. Copyright

Installation
------------
    gem install save_queue

Contributing
-------------
__Please help to improve this project!__

See [contributing guide](http://github.com/AlexParamonov/save_queue/blob/master/CONTRIBUTING.md) for best practices

Usage
-----

### Getting started

1. include SaveQueue:

        require 'save_queue'

        class Artice
          include SaveQueue
        end

2. call \#mark_as_changed method when object gets dirty:

        require 'save_queue'

        class Artice
          include SaveQueue

          def change_attribute attr, value
            @attributes ||= {}
            @attributes[attr] = value
            mark_as_changed # call this and object will be marked for save
          end
        end

3. add SaveQueue to some other classes (or implement #save and #has_unsaved_changes? in it):

        require 'save_queue'

        class Tag
          include SaveQueue

          @attributes ||= {}
          @attributes[attr] = value
          mark_as_changed # call this and object will be marked for save
        end

4. Add some functionality:

        class Artice
          def tags=(tag_objects)
            @tags = tag_objects
            save_queue.add_all tag_objects
          end

          def add_tag(tag)
            @tags ||= []
            @tags << tag
            save_queue.add tag # you may use also #<<, #push methods
          end
        end

6. Voila!

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

        # You may call save on queue explicitly:
        #
        # article.save_queue.save
        # article.save

7. Read README for more details :)


### Tracking changes
By default SaveQueue provide changes tracking functional.
In order to use it, call #mark_as_changed method in your mutator methods like this:

    require "save_queue"
    class Artice
      include SaveQueue

      def change_attribute attr, value
        @attributes[attr] = value
        mark_as_changed # call this and object will be marked for save
      end
    end

If you want to mark object as saved, you may use #mark_as_saved method. SaveQueue will automatically call #mark_as_saved
after saving an object.
This marks are used when SaveQueue calls #save. Object will be saved only, if it #has_unsaved_changes? returns true.
There are some docs from spec tests:

    #has_unsaved_changes?
      should return true for changed object
      should return false for unchanged object
      should return false for new object
      should return true if save_queue was changed by #add
      should return true if save_queue was changed by #<<
      should return true if save_queue was changed by #push

If you have custom logic for marking objects dirty then you may want to override
\#has_unsaved_changes? method, methods #mark_as_saved and #mark_as_changed in you class like this:

    def has_unsaved_changes?
      dirty? # dirty is your custom method to determine has object unsaved_changes or not
    end

    def mark_as_saved
      # your custom methods
    end

    def mark_as_changed
      # your custom methods
    end


### Error handling

SaveQueue assumes, that #save method returns true/false and #save! raise an Exception if save failed:

    unless article.save
      # You may use article.save_queue.errors.any? or article.save_queue.errors.empty? also

      # returns a [Hash] that contains information about saving proccess:
      # @option [Array<Object>] :processed
      # @option [Array<Object>] :saved
      # @option [Object]        :failed
      # @option [Array<Object>] :pending
      article.save_queue.errors[:save]
    end


    begin
      article.save!
    rescue SaveQueue::FailedSaveError => error

      # returns a [Hash] that contains information about saving proccess:
      # @option [Array<Object>] :processed
      # @option [Array<Object>] :saved
      # @option [Object]        :failed
      # @option [Array<Object>] :pending
      error.context

      article.save_queue.errors[:save] # also set
    end



Plugins
-------
I am trying to extract any "extra" functionality into separate plugins, that you may want to include.

### Validation

If you want to use validation, include SaveQueue::Plugins::Validation and implement #valid? method.
You may got failed objects from save_queue.errors\[:validation] array.
\save_queue.errors are empty if no errors occurs

        require 'save_queue'
        require 'save_queue/plugins/validation'

        class Artice
          include SaveQueue
          include SaveQueue::Plugins::Validation

          # @return [boolean]
          def valid?
            true
          end

          # ...
        end

There are specs for them:

    ValidQueue
      invalid objects
        save
          should not be saved
          should set errors
        save!
          should raise SaveQueue::FailedValidationError exception
          should set errors
      valid objects
        save
          should be saved
          should not set errors
        save!
          should not raise an exception
          should not set errors

Also you got more error hangling options:

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

You may catch both save and validation errors by

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

### Notification

If you want to use notification, include SaveQueue::Plugins::Notification.
You'll get object notified by #queue_changed_event method, which by default call #mark_as_changed method if queue was successfuly changed.
You may override this method in your object if you want to.

    class Artice
      include SaveQueue
      include SaveQueue::Plugins::Notification
    end

    article = Article.new
    article.mark_as_saved
    article.save_queue << tag
    article.should have_unsaved changes

    class Artice
      def queue_changed_event(result, object)
        super
        puts "queue was changed!"
      end
    end

    article = Article.new
    article.mark_as_saved
    article.save_queue << tag # "queue was changed!"
    article.should have_unsaved changes


Creating your own Queues
-------------------------

/ TODO

FAQ
---

__Q: I use #write method to store object, how can i use SaveQueue?__

A: You may implement save method like this:

    class Artice
      # @return [boolean]
      def save
        write
      end
    end

Note that SaveQueue assumes, that #save method returns true/false and #save! raise an Exception if save failed

__Q: Where i can get more information?__

A: See test specs for more details.

__How?__

clone git project by

    git clone git://github.com/AlexParamonov/save_queue.git

cd into it and run bundle

    cd save_queue
    bundle

and run rake

    rake


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
* jruby-18mode
* rbx-19mode
* rbx-18mode
* ruby-head
* ree

see [build history](http://travis-ci.org/#!/AlexParamonov/save_queue/builds)

Copyright
---------
Copyright © 2011-2012 Alexander N Paramonov.
Released under the MIT License. See the LICENSE file for further details.
