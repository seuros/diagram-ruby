# frozen_string_literal: true

module Diagrams
  # Periods and their events, grouped in sections (see Sectioned).
  class TimelineDiagram < Base
    include Sectioned

    collection :sections, add: :add_section

    # +periods+ are TimelinePeriod values or hashes of their members.
    def add_section(title: nil, periods: [])
      open_section(Elements::TimelineSection, title,
                   Check.elements(periods, :periods, Elements::TimelinePeriod)) do |period|
        add_period(**period)
      end
    end

    def add_period(label:, events:)
      add_to_section(Elements::TimelineSection, :periods, Elements::TimelinePeriod.new(label:, events:))
    end

    def periods = sections.flat_map(&:periods)
  end
end
