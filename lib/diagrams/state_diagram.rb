# frozen_string_literal: true

module Diagrams
  class StateDiagram < AbstractDiagram
    attribute :id, Types::String
    attribute :states, Types::Array.of(State)
    attribute :transitions, Types::Array.of(Transition)
  end
end
