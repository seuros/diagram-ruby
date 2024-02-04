# frozen_string_literal: true

module Diagrams
  class ClassDiagram
    class Class
      class Function
        class Argument < Dry::Struct
          attribute :name, ClassDiagram::Types::String
          attribute :type, ClassDiagram::Types::String.optional.default(nil)

          def to_json(*_args)
            {
              name:,
              type:
            }
          end
        end
      end
    end
  end
end
