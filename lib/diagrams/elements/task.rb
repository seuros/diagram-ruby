# frozen_string_literal: true

require 'dry-struct'
require_relative 'node' # Load Types module defined in node.rb

module Diagrams
  # Corrected namespace
  module Elements
    # Represents a task in a Gantt Diagram.
    class Task < Dry::Struct
      # Use the shared Types module
      include Elements::Types # Corrected namespace

      attribute :id, Types::Strict::String.constrained(min_size: 1)
      attribute :name, Types::Strict::String.constrained(min_size: 1)
      # Using String for dates initially for simplicity.
      # Consider Types::Strict::Date or custom coercible types later.
      attribute :start_date, Types::Strict::String.constrained(min_size: 1) # Basic check
      attribute :end_date, Types::Strict::String.constrained(min_size: 1)   # Basic check
      # TODO: Add dependencies attribute (e.g., Types::Strict::Array.of(Types::Strict::String))

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String}]
    end
  end
end
