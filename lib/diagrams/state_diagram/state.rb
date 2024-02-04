# frozen_string_literal: true

module Diagrams
  class StateDiagram
    class State < Dry::Struct
      attribute :id, StateDiagram::Types::String
      attribute :label, StateDiagram::Types::String.optional.default(nil)
      attribute :type,
                StateDiagram::Types::String.optional.default('state').enum('state', 'start', 'end', 'fork', 'join')

      def to_json(*_args)
        {
          id:,
          label:
        }
      end
    end
  end
end
