# frozen_string_literal: true

require 'dry-struct'
require_relative 'node' # Load Types module defined in node.rb

module Diagrams
  # Corrected namespace
  module Elements
    # Represents an event, potentially used in State Diagrams or others.
    class Event < Dry::Struct
      # Use the shared Types module
      include Elements::Types # Corrected namespace

      attribute :id, Types::Strict::String.constrained(min_size: 1)
      attribute :label, Types::Strict::String.optional.default(nil)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | nil}]
      def to_h
        # Rely on Dry::Struct's default to_h, filtering out nil label.
        super.compact
      end
    end
  end
end
