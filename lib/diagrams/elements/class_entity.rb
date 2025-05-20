# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a class entity in a UML Class Diagram.
    class ClassEntity < Dry::Struct
      # Use the shared Types module
      include Elements::Types

      # Name of the class
      attribute :name, Types::Strict::String.constrained(min_size: 1)

      # List of attributes (e.g., "id: Integer", "name: String")  # Maybe this need renaming to "fields"?
      attribute :attributes, Types::Strict::Array.of(Types::Strict::String).default([].freeze)

      # List of methods (e.g., "save()", "find(id: Integer)") # Maybe this need renaming to "functions"?
      attribute :methods, Types::Strict::Array.of(Types::Strict::String).default([].freeze)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | Array<String>}]
      def to_h
        {
          name:,
          attributes: self[:attributes],
          methods: self[:methods]
        }
      end
    end
  end
end
