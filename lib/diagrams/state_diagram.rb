# frozen_string_literal: true

module Diagrams
  class StateDiagram < AbstractDiagram
    attribute :id, Types::String
    attribute :states, Types::Array.of(State)
    attribute :transitions, Types::Array.of(Transition)
    attribute :events, Types::Array.of(Event)

    def type
      'state_machine'
    end

    def to_json(*_args)
      {
        id:,
        states: states.map(&:to_json),
        transitions: transitions.map(&:to_json),
        events: events.map(&:to_json)
      }
    end
  end
end
