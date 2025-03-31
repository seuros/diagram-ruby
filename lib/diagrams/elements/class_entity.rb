# frozen_string_literal: true

require 'dry-struct'
require_relative 'node' # Load Types module defined in node.rb

module Diagrams

  module Elements
    # Represents a class entity in a UML Class Diagram.
    class ClassEntity < Dry::Struct
      # Use the shared Types module
      include Elements::Types

      # Name of the class
      attribute :name, Types::Strict::String.constrained(min_size: 1)

      # List of attributes (e.g., "id: Integer", "name: String")
      attribute :attributes, Types::Strict::Array.of(Types::Strict::String).default([].freeze)

      # List of methods (e.g., "save()", "find(id: Integer)")
      attribute :methods, Types::Strict::Array.of(Types::Strict::String).default([].freeze)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | Array<String>}]
    end
  end
end
