# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a specific time period on the timeline, containing one or more events.
    class TimelinePeriod < Dry::Struct
      include Elements::Types

      attribute :label, Types::Strict::String.constrained(min_size: 1)
      attribute :events, Types::Strict::Array.of(TimelineEvent).constrained(min_size: 1)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | Array<Hash>}]
      def to_h
        {
          label:,
          events: events.map(&:to_h)
        }
      end
    end
  end
end