module SaveQueue
  class Queue
    def initialize
      @queue = []
    end

    def add_all objects
      Array(objects).each do |object|
        add object
      end
    end

    def add object
      raise ArgumentError, "#{object.inspect} does not include SaveQueue::Object" unless object.class.include? SaveQueue::Object
      @queue << object unless @queue.include? object
    end

    def save
      saved = []
      @queue.each do |object|
        if object.has_unsaved_changes?

          result = object.save
          raise FailedSaveError, {:saved => saved, :failed => object, :pending => @queue - (saved + [object])} if false == result

          saved << object
        end
      end
      @queue = []

      true
    end
  end

  class FailedSaveError < RuntimeError
    attr_reader :context
    def initialize(context_hash)
      @context = context_hash
    end

    def to_s # Some default way to display errors
      "#{super}: " + @context.to_s
    end
  end
end