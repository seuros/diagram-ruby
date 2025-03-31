# frozen_string_literal: true

require 'dry-struct'
require_relative 'node' # Load Types module defined in node.rb

module Diagrams
  # Corrected namespace
  module Elements
    # Represents a slice in a Pie Diagram.
    class Slice < Dry::Struct
      # Use the shared Types module
      include Elements::Types # Corrected namespace

      attribute :label, Types::Strict::String.constrained(min_size: 1)
      # Represents the raw value of the slice (not percentage)
      attribute :value, Types::Coercible::Float.constrained(gteq: 0)
      # Calculated percentage (read-only)
      attribute :percentage, Types::Strict::Float.optional.default(nil).meta(reader: true)
      # Consider adding optional color attribute later.
      # attribute :color, Types::Strict::String.optional.default(nil)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | Float | nil}]
    end
  end
end
