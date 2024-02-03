# frozen_string_literal: true

module Diagrams
  class ClassDiagram < AbstractDiagram
    attribute :classes, ClassDiagram::Types::Array.of(Class)
  end
end
