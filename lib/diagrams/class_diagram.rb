# frozen_string_literal: true

module Diagrams
  class ClassDiagram < AbstractDiagram
    attribute :classes, ClassDiagram::Types::Array.of(Class)

    def type
      'classes'
    end

    def to_json(*_args)
      {
        id:,
        classes: classes.map(&:to_json)
      }
    end
  end
end
