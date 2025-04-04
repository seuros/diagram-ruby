# frozen_string_literal: true

module Diagrams
  # Represents a timeline diagram illustrating a chronology of events.
  class TimelineDiagram < Base
    DEFAULT_SECTION_TITLE = 'Default Section'

    attr_reader :title, :sections

    # Initializes a new TimelineDiagram.
    #
    # @param title [String, nil] Optional title for the timeline.
    # @param sections [Array<Element::TimelineSection>] Initial sections (optional).
    # @param version [String, Integer, nil] User-defined version identifier.
    def initialize(title: nil, sections: [], version: 1)
      super(version:)
      @title = title&.strip
      @sections = Array(sections)
      # Ensure there's always at least a default section if none provided initially
      ensure_default_section if @sections.empty?
      update_checksum!
    end

    # Sets the title of the timeline.
    #
    # @param new_title [String] The title text.
    # @return [String] The new title.
    def set_title(new_title)
      @title = new_title.strip
      update_checksum!
      @title
    end

    # Adds a new section to the timeline.
    # Subsequent periods/events will be added to this section.
    #
    # @param section_title [String] The title of the section.
    # @raise [ArgumentError] if a section with the same title already exists.
    # @return [Elements::TimelineSection] The newly added section.
    def add_section(section_title)
      clean_title = section_title.strip
      raise ArgumentError, "Section title '#{clean_title}' cannot be empty" if clean_title.empty?
      raise ArgumentError, "Section with title '#{clean_title}' already exists" if find_section(clean_title)

      # Remove default section if it's empty and we're adding a real one
      if @sections.size == 1 && @sections.first.title == DEFAULT_SECTION_TITLE && @sections.first.periods.empty?
        @sections.clear
      end

      new_section = Elements::TimelineSection.new(title: clean_title)
      @sections << new_section
      update_checksum!
      new_section
    end

    # Adds a time period with one or more events to the current (last) section.
    #
    # @param period_label [String] The label for the time period (e.g., "2004", "Bronze Age").
    # @param events [Array<String> | String] A single event description or an array of event descriptions.
    # @raise [ArgumentError] if period_label or any event description is empty.
    # @raise [StandardError] if no sections exist (shouldn't happen due to default section).
    # @return [Elements::TimelinePeriod] The newly added period.
    def add_period(period_label:, events:)
      clean_label = period_label.strip
      raise ArgumentError, 'Period label cannot be empty' if clean_label.empty?

      event_list = Array(events).map(&:strip).reject(&:empty?)
      raise ArgumentError, 'Events cannot be empty' if event_list.empty?

      timeline_events = event_list.map { |desc| Elements::TimelineEvent.new(description: desc) }
      new_period = Elements::TimelinePeriod.new(label: clean_label, events: timeline_events)

      current_section = @sections.last
      raise StandardError, 'Cannot add period: No section available.' unless current_section

      # Add period to the current section's periods array
      # Dry::Struct arrays are immutable, so we need to create a new section object
      updated_periods = current_section.periods + [new_period]
      # Create a completely new section instance with the updated periods array
      updated_section = Elements::TimelineSection.new(title: current_section.title, periods: updated_periods)

      # Find the index of the current section and update it in place
      # Rebuild the sections array, replacing the modified section
      current_section_title = current_section.title
      # Rebuild the sections array by mapping, replacing the target section
      @sections = @sections.map do |section|
        section.title == current_section_title ? updated_section : section
      end

      update_checksum!
      new_period
    end

    # --- Base Class Implementation ---

    def to_h_content
      content = {
        sections: @sections.map(&:to_h)
      }
      content[:title] = @title if @title
      content
    end

    def identifiable_elements
      # Sections and Periods are the main identifiable structures. Events are nested.
      # Use section title and period label as identifiers.
      {
        sections: @sections,
        periods: @sections.flat_map(&:periods) # Flatten periods from all sections
      }
    end

    def self.from_h(data_hash, version:, checksum:)
      title = data_hash[:title] || data_hash['title']
      sections_data = data_hash[:sections] || data_hash['sections'] || []

      sections = sections_data.map do |section_h|
        section_data = section_h.transform_keys(&:to_sym)
        periods_data = section_data[:periods] || []
        periods = periods_data.map do |period_h|
          period_data = period_h.transform_keys(&:to_sym)
          events_data = period_data[:events] || []
          events = events_data.map do |event_h|
            event_data = event_h.transform_keys(&:to_sym)
            Elements::TimelineEvent.new(event_data)
          end
          Elements::TimelinePeriod.new(period_data.merge(events:))
        end
        Elements::TimelineSection.new(section_data.merge(periods:))
      end

      diagram = new(title:, sections:, version:)

      # Optional: Verify checksum
      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded TimelineDiagram (version: #{version}). Expected #{checksum}, got #{diagram.checksum}."
      end

      diagram
    end

    private

    # Ensures a default section exists if the sections array is empty.
    def ensure_default_section
      return if @sections.any? { |s| s.title == DEFAULT_SECTION_TITLE }

      @sections << Elements::TimelineSection.new(title: DEFAULT_SECTION_TITLE)
    end

    # Finds a section by its title.
    def find_section(section_title)
      @sections.find { |s| s.title == section_title }
    end

    # Protected method access for from_h
    protected :update_checksum!
  end
end
