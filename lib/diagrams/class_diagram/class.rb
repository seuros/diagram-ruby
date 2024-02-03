# frozen_string_literal: true

module Diagrams
  class ClassDiagram
    class Class < Dry::Struct
      attribute :id, ClassDiagram::Types::String.constrained(format: /\A[a-zA-Z0-9_-]+\z/)
      attribute :label, ClassDiagram::Types::String.optional.default(nil)
      attribute :fields, ClassDiagram::Types::Array.of(Field)
      attribute :functions, ClassDiagram::Types::Array.of(Function)
    end
  end
end
