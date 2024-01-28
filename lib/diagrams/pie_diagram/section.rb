# frozen_string_literal: true

module Diagrams
  class PieDiagram
    class Section < Dry::Struct
      attribute :label, PieDiagram::Types::String.optional.default(nil)
      attribute :value, PieDiagram::Types::Coercible::Float.optional.default(nil).constrained(gteq: 0)
      attribute :percentage, PieDiagram::Types::Coercible::Float.constrained(gteq: 0, lteq: 100).default(0)
    end
  end
end
