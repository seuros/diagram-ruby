# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a task in a Gantt Diagram.
    class Task < Dry::Struct
      # Use the shared Types module
      include Elements::Types

      # Status symbols allowed by Mermaid Gantt
      STATUS = Types::Strict::Symbol.enum(:done, :active, :crit)

      # Attributes
      attribute :id, Types::Strict::String.constrained(min_size: 1) # Unique ID for dependencies
      attribute :label, Types::Strict::String.constrained(min_size: 1) # Display name
      attribute :status, STATUS.optional.default(nil) # Task status (nil implies default/future)
      attribute :start, Types::Strict::String.constrained(min_size: 1) # Start date, task ID, or 'after taskX[, taskY]'
      attribute :duration, Types::Strict::String.constrained(min_size: 1) # Duration string (e.g., '7d', '2w')

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | Symbol | nil}]
      def to_h
        hash = {
          id: id,
          label: label,
          start: start,
          duration: duration
        }
        hash[:status] = status if status # Include status only if set
        hash
      end
    end
  end
end
