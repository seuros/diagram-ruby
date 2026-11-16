# frozen_string_literal: true

module Diagrams
  module Elements
    # A transition between two states, with an optional label, guard and action.
    Transition = Data.define(:source_state_id, :target_state_id, :label, :guard, :action) do
      include Element

      def initialize(source_state_id:, target_state_id:, label: nil, guard: nil, action: nil)
        super(
          source_state_id: Check.string(source_state_id, :source_state_id),
          target_state_id: Check.string(target_state_id, :target_state_id),
          label: Check.optional_string(label, :label),
          guard: Check.optional_string(guard, :guard),
          action: Check.optional_string(action, :action)
        )
      end
    end
  end
end
