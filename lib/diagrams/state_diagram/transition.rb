# frozen_string_literal: true

module Diagrams
  class StateDiagram
    class Transition < Dry::Struct
      attribute :id, StateDiagram::Types::String
      attribute :from, StateDiagram::Types::String
      attribute :to, StateDiagram::Types::String
      attribute :label, StateDiagram::Types::String.optional.default(nil)

      def to_json(*_args)
        {
          id:,
          from:,
          to:,
          label:
        }
      end
    end
  end
end
