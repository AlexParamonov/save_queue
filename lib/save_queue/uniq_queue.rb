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
      @queue << object unless @queue.include? object
    end
    alias_method :push, :add
    alias_method :<<,   :add
  end
end