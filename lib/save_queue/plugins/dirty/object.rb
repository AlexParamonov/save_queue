module SaveQueue
  module Plugins
    module Dirty
      module Object
        def mark_as_changed
          @_changed_mark = true
        end

        def mark_as_saved
          @_changed_mark = false
        end

        # @returns [Boolean] true if object has been modified
        def has_unsaved_changes?
          @_changed_mark ||= false
        end

        private
        def _sq_around_original_save
          result = nil
          if has_unsaved_changes?
            result = yield
            mark_as_saved
          end

          result
        end
      end
    end
  end
end
