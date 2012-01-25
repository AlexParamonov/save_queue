require 'forwardable'
module SaveQueue
  class UniqQueue
    extend ::Forwardable
    DELEGATED_METHODS = [:empty?,
                         :any?,
                         :size,
                         :count,
                         :clear,
                         :inspect,
                         :to_s,
                         :first,
                         :last,
                         :pop,
                         :shift]

    def_delegators :@queue, *DELEGATED_METHODS
    
    def initialize
      @queue = []
    end

    def add_all objects
      Array(objects).each do |object|
        add object
      end
    end

    def add object
      return false if @queue.include? object
      @queue << object

      true
    end

    #alias_method :push, :add # Not working as expected: does not save inheritance
    def push(*args)
      add *args
    end
    
    def << *args
      add *args
      self
    end
  end
end