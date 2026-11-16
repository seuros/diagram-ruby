# frozen_string_literal: true

module Diagrams
  module Elements
    # A timeline period ("2004", "Bronze Age") and its events.
    TimelinePeriod = Data.define(:label, :events) do
      include Element

      def initialize(label:, events:)
        events = Check.strings(events, :events)
        raise ArgumentError, 'events cannot be empty' if events.empty?

        super(label: Check.string(label, :label), events:)
      end

      def key = label
    end
  end
end
