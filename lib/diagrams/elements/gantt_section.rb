# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a section within a Gantt chart, grouping multiple tasks.
    class GanttSection < Dry::Struct
      include Elements::Types

      attribute :title, Types::Strict::String.constrained(min_size: 1)
      attribute :tasks, Types::Strict::Array.of(Task).default([].freeze)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | Array<Hash>}]
      def to_h
        {
          title:,
          tasks: tasks.map(&:to_h)
        }
      end
    end
  end
end
