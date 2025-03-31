# frozen_string_literal: true

require 'dry-struct'
require 'dry-types'

module Diagrams
  # Namespace for diagram element value objects.
  # Corrected namespace
  module Elements
    # Common Dry::Types definitions for elements.
    module Types
      include Dry.Types()
    end

    # Represents a node in various diagram types (e.g., Flowchart).
    # Typically has an identifier and a display label.
    class Node < Dry::Struct
      # Use the shared Types module
      include Elements::Types # Corrected namespace

      attribute :id, Types::Strict::String.constrained(min_size: 1)
      attribute :label, Types::Strict::String.constrained(min_size: 1)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String}]
      def to_h
        {
          id:,
          label:
        }
        # Dry::Struct automatically provides a to_h method,
        # but defining it explicitly ensures the desired structure.
        # super # Alternatively, call super if the default is sufficient.
      end
    end
  end
end
