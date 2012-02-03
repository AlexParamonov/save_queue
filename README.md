Save Queue
==========
[![Build Status](https://secure.travis-ci.org/AlexParamonov/save_queue.png)](http://travis-ci.org/AlexParamonov/save_queue)
[![Gemnasium Build Status](https://gemnasium.com/AlexParamonov/save_queue.png)](http://gemnasium.com/AlexParamonov/save_queue)

Save Queue creates queue of objects inside holder object.  
Queue will be saved and cleared after successfull holder object save.   
  

**Holder object** is object that include SaveQueue.  
**Object in queue** is any instance of any class, that include SaveQueue or respond to #save method.  


There are plugins, that alter queue or holder object behavior, find them in 'save_queue/plugins' directory and read about
them in Plugins section of [readme](https://github.com/AlexParamonov/save_queue/blob/develop/README.md)

Contents
---------
1. Installation
1. Contributing
1. Usage
    * Getting started
    * Error handling
1. Plugins
    * Dirty
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
**Please help to improve this project!**  


See [contributing guide](http://github.com/AlexParamonov/save_queue/blob/master/CONTRIBUTING.md) for best practices  
I am using [gitflow](https://github.com/nvie/gitflow). Develop branch is most featured and usually far above master.

Usage
-----

### Getting started

1. Include SaveQueue:

        require 'save_queue'

        class Artice
          include SaveQueue

          def save
            puts "article saved!"
          end
        end

1. Add SaveQueue to some other classes (or implement #save method in it):

        require 'save_queue'

        class Tag
          include SaveQueue

          def save
            puts "tag saved!"
          end
        end

1. Add some functionality:

        class Artice
          def tags=(tag_objects)
            @tags = tag_objects
            save_queue.add_all tag_objects
          end

          def add_tag(tag)
            @tags ||= []
            @tags << tag
            save_queue.add tag # methods #<<, #push can be also used to add object to queue
            # You may also do
            # tag.save_queue << self
            # save_queue will not circle in this case
          end
        end

1. Voila!

        article = Article.new

        # Create 3 tags and add them to the article
        article.tags =
          3.times.map do
            tag = Tag.new
            tag.should_receive(:save).once

            tag
          end

        # Add single tag
        tag = Tag.new
        tag.should_receive(:save).once

        article.add_tag tag

        # that will save article and all tags in this article if article.save
        # and all tag.save returns true.
        # You may also use #save! method, that will delegate to article.save! and
        # raise SaveQueue::FailedSaveError on fail
        article.save.should be_true

        # Output:
        # article saved!
        # tag saved!
        # tag saved!
        # tag saved!
        # tag saved!

        # empty the queue after successfull save
        article.save_queue.should be_empty

        article.save
        # Output:
        # article saved!

        # You may call save on queue explicitly:
        #
        # article.save_queue.save
        # article.save

1. To save object _only_ if it was changed, include Dirty module described below.

1. Continue reading for more details.

### Error handling

SaveQueue assumes, that #save method returns true/false and #save! raise an Exception if save failed:

    unless article.save
      # You may use article.save_queue.errors.any? or article.save_queue.errors.empty? also

      # returns a [Hash] that contains information about saving proccess:
      # @option [Array<Object>] :saved
      # @option [Object]        :failed
      # @option [Array<Object>] :pending
      article.save_queue.errors[:save]
    end


    begin
      article.save!
    rescue SaveQueue::FailedSaveError => error

      # returns a [Hash] that contains information about saving proccess:
      # @option [Array<Object>] :saved
      # @option [Object]        :failed
      # @option [Array<Object>] :pending
      error.context

      article.save_queue.errors[:save] # also set
    end

Queue is not cleared after fail. Possible to fix errors and rerun queue.save

Plugins
-------
Any extract any "extra" functionality goes into bundled plugins.

### Dirty

SaveQueue::Plugins::Dirty module provide changes tracking functional.  
In order to use it include this module and call #mark_as_changed method in mutator methods like this:

    require "save_queue"
    require "save_queue/plugins/dirty"

    class Artice
      include SaveQueue
      include SaveQueue::Plugins::Dirty

      def initialize
        @attributes = {}
      end

      def change_attribute attr, value
        @attributes[attr] = value
        mark_as_changed # call this and object will be marked for a save
      end
    end

To mark object as saved, call #mark_as_saved method. SaveQueue Dirty plugin will automatically call
\#mark_as_saved method after saving an object.  
This marks are used when SaveQueue calls #save. Object will be saved only, if it #has_unsaved_changes? method returns true.
There are some docs from spec tests:

    #has_unsaved_changes?
      should return true for changed object
      should return false for unchanged object
      should return false for new object

If you have custom logic for marking objects dirty then you may want to overwrite
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


### Validation

To use validation include SaveQueue::Plugins::Validation and implement #valid? method.  
Failed objects are stored in save_queue.errors\[:validation] array.  
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

    SaveQueue::Plugins::Validation::Queue
      is empty
        should be valid
        #save
          should be true
        #save!
          should not raise Exception
      contains valid objects
        #save
          should be true
          should save all elements
        #save!
          should not raise Exception
          should save all elements
        #valid?
          should be true
          should not has any errors
        #validate!
          should not raise any exception
          should not has any errors
      contains invalid objects
        behaves like queue with invalid objects
          #save
            should be false
            should not save elements
          #save!
            should raise SaveQueue::FailedValidationError
            should not save elements
          #valid?
            should be false
            should set errors
          #validate!
            should raise SaveQueue::FailedValidationError exception
            should set errors
      contains mix of valid and invalid objects
        #save should call #valid?
        #save! should call #validate!
        behaves like queue with invalid objects
          #save
            should be false
            should not save elements
          #save!
            should raise SaveQueue::FailedValidationError
            should not save elements
          #valid?
            should be false
            should set errors
          #validate!
            should raise SaveQueue::FailedValidationError exception
            should set errors

Plugin adds SaveQueue::FailedValidationError:

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

To catch both save and validation errors use SaveQueue::Error:

    begin
      article.save!
    rescue SaveQueue::Error
      # do something
    end

To not save an object if save_queue is invalid, add this condition to #save method:

    def save
      return false unless save_queue.valid?
      #..
    end

or add it to validation (to object#valid? method for example).  
Note, that queue#valid? and queue#validate return true/false and queue#validate! raises SaveQueue::FailedValidationError exception.
Queue is not creared if validation fails.

### Notification

To use notification include SaveQueue::Plugins::Notification.  
Holder object will be notified by #queue_changed_event method.  
Overwrite this method to implement your functionality, for ex logging.

    require 'save_queue/plugins/notification'

    class Artice
      include SaveQueue
      include SaveQueue::Plugins::Notification
    end

    article = Article.new
    article.save_queue << tag # this will trigger callback #queue_changed_event on article


    class Artice
      def queue_changed_event(result, object)
        puts "queue was changed!"
      end
    end

    article = Article.new
    article.save_queue.add tag # Outputs "queue was changed!"


Creating your own Queues
-------------------------

/ TODO

FAQ
---

__Q: I use #write method to store object, how can i use SaveQueue?__  
A: You may implement #save method like this:

    class Artice
      # @return [boolean]
      def save
        write
      end
    end

Note that SaveQueue assumes, that #save method returns true/false and #save! raise an Exception if save failed.


__Q: Where i can get more information?__  
A: See test specs for more details.  
__How?__  
clone git project by

    git clone git://github.com/AlexParamonov/save_queue.git

cd into it and run bundle

    cd save_queue
    bundle

and then rake

    rake

docs will be printed to your console :)

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
* jruby-19mode
* rbx-19mode
* rbx-18mode
* ruby-head
* ree

see [build history](http://travis-ci.org/#!/AlexParamonov/save_queue/builds)

Copyright
---------
Copyright © 2011-2012 Alexander N Paramonov.
Released under the MIT License. See the LICENSE file for further details.
