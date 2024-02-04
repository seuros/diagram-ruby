# frozen_string_literal: true

module Diagrams
  class PieDiagram
    class Section < Dry::Struct
      attribute :id, PieDiagram::Types::String
      attribute :label, PieDiagram::Types::String.optional.default(nil)
      attribute :value, PieDiagram::Types::Coercible::Float.optional.default(0).constrained(gteq: 0)

      def to_json(*_args)
        {
          id:,
          label:,
          value:
        }
      end
    end
  end
end
