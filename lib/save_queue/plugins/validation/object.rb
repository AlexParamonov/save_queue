module SaveQueue
  module Plugins
    module Validation
      module Object

        # @return [Boolean]
        def save(*args)
          # are objects in queue valid?
          return false unless valid?
          return false unless save_queue.valid?
        end
      end
    end
  end
end
