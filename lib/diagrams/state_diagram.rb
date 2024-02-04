# frozen_string_literal: true

module Diagrams
  class StateDiagram < AbstractDiagram
    attribute :id, Types::String
    attribute :title, Types::String.optional.default(nil)
    attribute :states, Types::Array.of(State).optional.default([])
    attribute :transitions, Types::Array.of(Transition).optional.default([])
    attribute :events, Types::Array.of(Event).optional.default([])

    def type
      'state_machine'
    end

    def add_state(*args)
      state = State.new(*args)
      attributes[:states] = attributes[:states] + [state]
      state
    end

    def remove_state(state_id)
      attributes[:states] = attributes[:states].reject { |state| state.id == state_id }
    end

    def add_transition(*args)
      transition = Transition.new(*args)
      attributes[:transitions] = attributes[:transitions] + [transition]
      transition
    end

    def remove_transition(transition_id)
      attributes[:transitions] = attributes[:transitions].reject { |transition| transition.id == transition_id }
    end

    def add_event(*args)
      event = Event.new(*args)
      attributes[:events] = attributes[:events] + [event]
      event
    end

    def remove_event(event_id)
      attributes[:events] = attributes[:events].reject { |event| event.id == event_id }
    end

    def to_json(*_args)
      {
        id:,
        title:,
        type:,
        states: states.map(&:to_json),
        transitions: transitions.map(&:to_json),
        events: events.map(&:to_json)
      }
    end
  end
end
