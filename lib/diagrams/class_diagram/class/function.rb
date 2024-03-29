# frozen_string_literal: true

module Diagrams
  class ClassDiagram
    class Class
      class Function < Dry::Struct
        attribute :name, ClassDiagram::Types::String
        attribute :return_type, ClassDiagram::Types::String.optional.default('void')
        attribute :arguments, ClassDiagram::Types::Array.of(Argument)
        attribute :visibility,
                  ClassDiagram::Types::String.optional.default('public')
                                             .constrained(format: /\A(public|private|protected)\z/)

        def to_json(*_args)
          {
            name:,
            return_type:,
            arguments:,
            visibility:
          }
        end
      end
    end
  end
end
