module SaveQueue
  class Error < RuntimeError; end
  class FailedSaveError < Error
    attr_reader :context
    
    def initialize(context_hash)
      @context = context_hash
    end

    def to_s
      "#{super}: " + @context.to_s
    end
  end
end