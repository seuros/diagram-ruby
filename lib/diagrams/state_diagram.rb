# frozen_string_literal: true

module Diagrams
  # States and the transitions between them. A transition may start or end at
  # TERMINAL, the initial/final pseudo-state, without declaring it.
  class StateDiagram < Base
    TERMINAL = '*'

    collection :states, add: :add_state
    collection :transitions, add: :add_transition

    def add_state(id:, label: nil)
      state = Elements::State.new(id:, label:)
      raise ArgumentError, "#{TERMINAL.inspect} is the terminal pseudo-state, not a state id" if state.id == TERMINAL

      append(:states, state)
    end

    def add_transition(source_state_id:, target_state_id:, label: nil, guard: nil, action: nil)
      transition = Elements::Transition.new(source_state_id:, target_state_id:, label:, guard:, action:)
      [transition.source_state_id, transition.target_state_id].each do |id|
        find!(:states, id, 'state') unless id == TERMINAL
      end
      append(:transitions, transition)
    end
  end
end
