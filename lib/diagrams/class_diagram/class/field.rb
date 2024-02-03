# frozen_string_literal: true

module Diagrams
  class ClassDiagram
    class Class
      class Field < Dry::Struct
        attribute :name, ClassDiagram::Types::String
        attribute :type, ClassDiagram::Types::String.optional.default('String')
        attribute :visibility,
                  ClassDiagram::Types::String.optional.default('public')
                                             .constrained(format: /\A(public|private|protected|Internal)\z/)
      end
    end
  end
end
