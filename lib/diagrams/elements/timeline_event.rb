# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a single event description within a timeline period.
    class TimelineEvent < Dry::Struct
      include Elements::Types

      attribute :description, Types::Strict::String.constrained(min_size: 1)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String}]
      def to_h
        {
          description:
        }
      end
    end
  end
end
