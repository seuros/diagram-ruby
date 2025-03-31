# frozen_string_literal: true

require_relative 'base'
require_relative 'elements/state'
require_relative 'elements/transition'
require_relative 'elements/event' # Assuming events are still desired

module Diagrams
  # Represents a State Diagram consisting of states and transitions between them.
  class StateDiagram < Base
    attr_reader :title, :states, :transitions, :events

    # Initializes a new StateDiagram.
    #
    # @param title [String] Optional title for the diagram.
    # @param states [Array<Element::State>] An array of state objects.
    # @param transitions [Array<Element::Transition>] An array of transition objects.
    # @param events [Array<Element::Event>] An array of event objects (optional).
    # @param version [String, Integer, nil] User-defined version identifier.
    def initialize(title: '', states: [], transitions: [], events: [], version: 1)
      super(version:)
      @title = title.is_a?(String) ? title : ''
      @states = states.is_a?(Array) ? states : []
      @transitions = transitions.is_a?(Array) ? transitions : []
      @events = events.is_a?(Array) ? events : [] # Keep events for now
      validate_elements!
      update_checksum!
    end

    # Adds a state to the diagram.
    #
    # @param state [Element::State] The state object to add.
    # @raise [ArgumentError] if a state with the same ID already exists.
    # @return [Element::State] The added state.
    def add_state(state)
      raise ArgumentError, 'State must be a Diagrams::Elements::State' unless state.is_a?(Diagrams::Elements::State)
      raise ArgumentError, "State with ID '#{state.id}' already exists" if find_state(state.id)

      @states << state
      update_checksum!
      state
    end

    # Adds a transition to the diagram.
    #
    # @param transition [Element::Transition] The transition object to add.
    # @raise [ArgumentError] if the transition refers to non-existent state IDs.
    # @return [Element::Transition] The added transition.
    def add_transition(transition)
      unless transition.is_a?(Diagrams::Elements::Transition)
        raise ArgumentError,
              'Transition must be a Diagrams::Elements::Transition'
      end
      unless find_state(transition.source_state_id) && find_state(transition.target_state_id)
        raise ArgumentError,
              "Transition refers to non-existent state IDs ('#{transition.source_state_id}' or '#{transition.target_state_id}')"
      end

      @transitions << transition
      update_checksum!
      transition
    end

    # Adds an event to the diagram.
    #
    # @param event [Element::Event] The event object to add.
    # @raise [ArgumentError] if an event with the same ID already exists.
    # @return [Element::Event] The added event.
    def add_event(event)
      raise ArgumentError, 'Event must be a Diagrams::Elements::Event' unless event.is_a?(Diagrams::Elements::Event)
      raise ArgumentError, "Event with ID '#{event.id}' already exists" if find_event(event.id)

      @events << event
      update_checksum!
      event
    end

    # Finds a state by its ID.
    #
    # @param state_id [String] The ID of the state to find.
    # @return [Element::State, nil] The found state or nil.
    def find_state(state_id)
      @states.find { |s| s.id == state_id }
    end

    # Finds an event by its ID.
    #
    # @param event_id [String] The ID of the event to find.
    # @return [Element::Event, nil] The found event or nil.
    def find_event(event_id)
      @events.find { |e| e.id == event_id }
    end

    # Returns the specific content of the state diagram as a hash.
    # Called by `Diagrams::Base#to_h`.
    #
    # @return [Hash{Symbol => String | Array<Hash>}]
    def to_h_content
      {
        title: @title,
        states: @states.map(&:to_h),
        transitions: @transitions.map(&:to_h),
        events: @events.map(&:to_h)
      }
    end

    # Class method to create a StateDiagram from a hash.
    # Used by the deserialization factory in `Diagrams::Base`.
    #
    # @param data_hash [Hash] Hash containing `:title`, `:states`, `:transitions`, `:events`.
    # @param version [String, Integer, nil] Diagram version.
    # @param checksum [String, nil] Expected checksum (optional, for verification).
    # @return [StateDiagram] The instantiated diagram.
    def self.from_h(data_hash, version:, checksum:)
      title = data_hash[:title] || data_hash['title'] || ''
      states_data = data_hash[:states] || data_hash['states'] || []
      transitions_data = data_hash[:transitions] || data_hash['transitions'] || []
      events_data = data_hash[:events] || data_hash['events'] || []

      states = states_data.map { |state_h| Diagrams::Elements::State.new(state_h.transform_keys(&:to_sym)) }
      transitions = transitions_data.map do |trans_h|
        Diagrams::Elements::Transition.new(trans_h.transform_keys(&:to_sym))
      end
      events = events_data.map { |event_h| Diagrams::Elements::Event.new(event_h.transform_keys(&:to_sym)) }

      diagram = new(title:, states:, transitions:, events:, version:)

      # Optional: Verify checksum if provided
      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded StateDiagram (version: #{version}). Expected #{checksum}, got #{diagram.checksum}."
        # Or raise an error: raise "Checksum mismatch..."
      end

      diagram
    end

    private

    # Validates the consistency of elements during initialization.
    def validate_elements!
      state_ids = @states.map(&:id)
      raise ArgumentError, 'Duplicate state IDs found' unless state_ids.uniq.size == @states.size

      event_ids = @events.map(&:id)
      raise ArgumentError, 'Duplicate event IDs found' unless event_ids.uniq.size == @events.size

      @transitions.each do |t|
        unless state_ids.include?(t.source_state_id) && state_ids.include?(t.target_state_id)
          raise ArgumentError,
                "Transition refers to non-existent state IDs ('#{t.source_state_id}' or '#{t.target_state_id}')"
        end
      end
      # Add more validation if needed (e.g., transition labels match event IDs?)
    end
  end
end
