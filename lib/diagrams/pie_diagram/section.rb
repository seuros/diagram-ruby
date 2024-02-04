# frozen_string_literal: true

module Diagrams
  class PieDiagram
    class Section < Dry::Struct
      attribute :label, PieDiagram::Types::String.optional.default(nil)
      attribute :value, PieDiagram::Types::Coercible::Float.optional.default(0).constrained(gteq: 0)

      def to_json(*_args)
        {
          label:,
          value:
        }
      end
    end
  end
end
