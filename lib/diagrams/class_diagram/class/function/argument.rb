# frozen_string_literal: true

module Diagrams
  class ClassDiagram
    class Class
      class Function
        class Argument < Dry::Struct
          attribute :name, ClassDiagram::Types::String
          attribute :type, ClassDiagram::Types::String.optional.default(nil)
        end
      end
    end
  end
end
