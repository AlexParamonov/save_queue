require 'forwardable'
# TODO remove hooks or extract to a module
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

    before_add :check_requirements

    # @return [Hash] save
    # @option save [Array<Object>] :saved
    # @option save [Object]        :failed
    # @option save [Array<Object>] :pending
    attr_reader :errors

    def initialize(*args)
      super
      @errors = {}
    end

    def add object
      run_hook :before_add, object

      result = super object

      run_hook :after_add, result, object

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

      @queue.each do |object|
        if false == object.save
          @errors[:save] = {:saved => saved, :failed => object, :pending => @queue - (saved + [object])}
          raise FailedSaveError, errors[:save]
        end

        saved << object
      end
      clear

      run_hook :after_save

      true
    end

    private
    def check_requirements(object)
      [:save].each do |method|
        raise ArgumentError, "#{object.inspect} does not respond to ##{method}" unless object.respond_to? method
      end
    end
  end
end