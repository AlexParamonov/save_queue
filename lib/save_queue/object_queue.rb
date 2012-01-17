require 'forwardable'
require 'save_queue/uniq_queue'

module SaveQueue
  class ObjectQueue < UniqQueue
    def add object
      check_requirements_for object
      super object
    end

    def save
      saved     = []
      processed = []

      @queue.each do |object|
        if object.has_unsaved_changes?

          result = object.save
          raise FailedSaveError, {:processed => processed, :saved => saved, :failed => object, :pending => @queue - (saved + [object])} if false == result

          saved << object
        end
        processed << object
      end

      @queue.clear

      true
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