require "save_queue/plugins/validation/exceptions"

module SaveQueue
  module Plugins
    module Validation
      module Queue
        def self.included base
          base.before_save :validate! if base.respond_to? :before_save
        end

        def valid?
          validate
        end

        def validate
          @queue.each do |object|
            unless object.valid?
              @errors[:validation] ||= []
              @errors[:validation].push(object)
            end
          end
          
          @errors.empty?
        end

        def validate!
          raise FailedValidationError, @errors[:validation] unless valid?
          true
        end
      end
    end
  end
end
