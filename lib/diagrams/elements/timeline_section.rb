# frozen_string_literal: true

module Diagrams
  module Elements
    # A group of timeline periods. Only the leading section may be untitled.
    TimelineSection = Data.define(:title, :periods) do
      include Element

      def initialize(title: nil, periods: [])
        super(title: Check.optional_string(title, :title), periods: Check.elements(periods, :periods, TimelinePeriod))
      end

      def key = title
    end
  end
end
