module SaveQueue
  module Plugins
    module Validation
      # Should be included AFTER SaveQueue
      module Object
        module RunAlwaysFirst
          # @return [Boolean]
          def save(*args)
            # are objects in queue valid?
            return false unless valid?
            return false unless save_queue.valid?

            super
          end
        end

        def initialize(*args)
          super
          # this will make RunAlwaysFirst methods triggered first in inheritance tree
          extend RunAlwaysFirst
        end
      end
    end
  end
end
