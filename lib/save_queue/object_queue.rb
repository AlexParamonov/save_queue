require 'forwardable'
require 'hooks'
require 'save_queue/uniq_queue'

module SaveQueue
  class ObjectQueue < UniqQueue
    include Hooks

    define_hook :before_save
    # triggered only after successful save
    define_hook :after_save

    define_hook :before_add
    define_hook :after_add

    # @return [Hash] save
    # @option save [Array<Object>] :processed
    # @option save [Array<Object>] :saved
    # @option save [Object]        :failed
    # @option save [Array<Object>] :pending
    attr_reader :errors
    def initialize(*args)
      super
      @errors = {}
    end

    def add object
      run_hook :before_add

      check_requirements_for object
      result = super object

      run_hook :after_add

      result
    end

    def save
      save!
      true
    rescue SaveQueue::Error
      false
    end

    def save!
      run_hook :before_save
      @errors = {}
      saved     = []
      processed = []

      @queue.each do |object|
        if object.has_unsaved_changes?

          result = object.save
          if false == result
            @errors[:save] = {:processed => processed, :saved => saved, :failed => object, :pending => @queue - (saved + [object])}
            raise FailedSaveError, errors[:save]
          end

          saved << object
        end
        processed << object
      end

      @queue.clear

      run_hook :after_save
      true
    end


    private
    def check_requirements_for object
      [:save, :has_unsaved_changes?].each do |method|
        raise ArgumentError, "#{object.inspect} does not respond to ##{method}" unless object.respond_to? method
      end
    end
  end
end