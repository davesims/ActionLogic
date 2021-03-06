require 'action_logic/action_includes'

module ActionLogic
  module ActionCoordinator

    def self.included(klass)
      klass.extend ActionLogic::ActionIncludes
      klass.extend ClassMethods
    end

    module ClassMethods
      def execute(params = {})
        around(params) do |execution_context|
          execution_context.call

          next_execution_context = execution_context.plan.keys.first

          while (next_execution_context) do
            execution_context.context = next_execution_context.execute(execution_context.context)
            next_execution_context = execution_context.plan[next_execution_context][execution_context.context.status]

            # From the perspective of the coordinator, the status of the context should be
            # :success as long as the state transition plan defines the next execution context
            # for a given current exection context and its resulting context state.
            # However, because normally a context in a state of :halted or :failure would
            # be considered a "breaking" state, the status of a context that is :halted or :failure
            # has to be reset to the default :success status only within the execution context of
            # the coordinator and only when the next execution context is defined within the
            # state transition plan. Otherwise, the context is return as is, without mutating its :status.
            execution_context.context.status = :success if next_execution_context
          end

          execution_context.context
        end
      end

      def __private__type
        "coordinator"
      end
    end
  end
end
