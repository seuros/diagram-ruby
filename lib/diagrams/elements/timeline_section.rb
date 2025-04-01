# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a section or age within the timeline, grouping multiple time periods.
    class TimelineSection < Dry::Struct
      include Elements::Types

      attribute :title, Types::Strict::String.constrained(min_size: 1)
      attribute :periods, Types::Strict::Array.of(TimelinePeriod).default([].freeze)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | Array<Hash>}]
      def to_h
        {
          title:,
          periods: periods.map(&:to_h)
        }
      end
    end
  end
end