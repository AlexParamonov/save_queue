require 'forwardable'
require 'save_queue/uniq_queue'

module SaveQueue
  class ObjectQueue < UniqQueue
    attr_reader :errors
    def initialize(*args)
      super
      @errors = {}
    end

    def add object
      check_requirements_for object
      super object
    end

    def save
      @errors = {}
      saved     = []
      processed = []

      @queue.each do |object|
        if object.has_unsaved_changes?

          result = object.save
          if false == result
            @errors[:save] = {:processed => processed, :saved => saved, :failed => object, :pending => @queue - (saved + [object])}
            return false
          end

          saved << object
        end
        processed << object
      end

      @queue.clear

      true
    end

    def save!
      if false == save
        raise FailedSaveError, errors[:save]
      end
    end


    private
    def check_requirements_for object
      [:save, :has_unsaved_changes?].each do |method|
        raise ArgumentError, "#{object.inspect} does not respond to ##{method}" unless object.respond_to? method
      end
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