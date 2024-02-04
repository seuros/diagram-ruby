# frozen_string_literal: true

module Diagrams
  class StateDiagram
    class Event < Dry::Struct
      attribute :id, StateDiagram::Types::String
      attribute :label, StateDiagram::Types::String.optional.default(nil)

      def to_json(*_args)
        {
          id:,
          label:
        }
      end
    end
  end
end
