# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class TimelineDiagramTest < Minitest::Test
    def setup
      @diagram = TimelineDiagram.new
    end

    def test_initialization_default
      assert_instance_of TimelineDiagram, @diagram
      assert_nil @diagram.title
      assert_equal 1, @diagram.sections.size
      assert_equal TimelineDiagram::DEFAULT_SECTION_TITLE, @diagram.sections.first.title
      assert_empty @diagram.sections.first.periods
      refute_nil @diagram.checksum
    end

    def test_initialization_with_title
      diagram = TimelineDiagram.new(title: ' My Timeline ')
      assert_equal 'My Timeline', diagram.title
    end

    def test_set_title
      old_checksum = @diagram.checksum
      @diagram.set_title(' History ')
      assert_equal 'History', @diagram.title
      refute_equal old_checksum, @diagram.checksum
    end

    def test_add_section
      old_checksum = @diagram.checksum
      section = @diagram.add_section(' First Section ')
      assert_equal 1, @diagram.sections.size # Default section removed
      assert_equal 'First Section', section.title
      assert_equal section, @diagram.sections.last
      refute_equal old_checksum, @diagram.checksum

      # Add another section
      section2 = @diagram.add_section('Second Section')
      assert_equal 2, @diagram.sections.size
      assert_equal section2, @diagram.sections.last
    end

    def test_add_section_duplicate_title
      @diagram.add_section('Section 1')
      assert_raises(ArgumentError, /Section with title 'Section 1' already exists/) do
        @diagram.add_section(' Section 1 ')
      end
    end

    def test_add_section_empty_title
      assert_raises(ArgumentError, /Section title '' cannot be empty/) do
        @diagram.add_section('  ')
      end
    end

    def test_add_period_to_default_section
      old_checksum = @diagram.checksum
      period = @diagram.add_period(period_label: ' 2002 ', events: ' Event A ')
      assert_equal 1, @diagram.sections.size
      current_section = @diagram.sections.first
      assert_equal TimelineDiagram::DEFAULT_SECTION_TITLE, current_section.title
      assert_equal 1, current_section.periods.size
      assert_equal period, current_section.periods.first
      assert_equal '2002', period.label
      assert_equal 1, period.events.size
      assert_equal 'Event A', period.events.first.description
      refute_equal old_checksum, @diagram.checksum
    end

    def test_add_period_to_custom_section
      @diagram.add_section('Custom Section')
      period = @diagram.add_period(period_label: '10:00', events: ['Event B', 'Event C'])

      assert_equal 1, @diagram.sections.size
      current_section = @diagram.sections.first
      assert_equal 'Custom Section', current_section.title
      assert_equal 1, current_section.periods.size
      assert_equal period, current_section.periods.first
      assert_equal '10:00', period.label
      assert_equal 2, period.events.size
      assert_equal 'Event B', period.events[0].description
      assert_equal 'Event C', period.events[1].description
    end

     def test_add_period_multiple_to_same_section
      @diagram.add_section('My Section')
      period1 = @diagram.add_period(period_label: 'Morning', events: 'Wake up')
      period2 = @diagram.add_period(period_label: 'Afternoon', events: 'Work')

      assert_equal 1, @diagram.sections.size
      current_section = @diagram.sections.first
      assert_equal 2, current_section.periods.size
      assert_equal period1, current_section.periods[0]
      assert_equal period2, current_section.periods[1]
    end

    def test_add_period_to_different_sections
      section1 = @diagram.add_section('Section A')
      period_a = @diagram.add_period(period_label: 'A1', events: 'Event A')
      section2 = @diagram.add_section('Section B')
      period_b = @diagram.add_period(period_label: 'B1', events: 'Event B')

      assert_equal 2, @diagram.sections.size
      # Re-fetch sections after potential modifications due to add_period
      fetched_section1 = @diagram.sections.find { |s| s.title == 'Section A' }
      fetched_section2 = @diagram.sections.find { |s| s.title == 'Section B' }
      assert_equal fetched_section1, @diagram.sections[0]
      assert_equal fetched_section2, @diagram.sections[1]
      assert_equal 1, fetched_section1.periods.size
      assert_equal [period_a], fetched_section1.periods
      assert_equal 1, fetched_section2.periods.size
      assert_equal [period_b], fetched_section2.periods
    end

    def test_add_period_empty_label
      assert_raises(ArgumentError, /Period label cannot be empty/) do
        @diagram.add_period(period_label: ' ', events: 'Event A')
      end
    end

    def test_add_period_empty_events
      assert_raises(ArgumentError, /Events cannot be empty/) do
        @diagram.add_period(period_label: '2024', events: [])
      end
      assert_raises(ArgumentError, /Events cannot be empty/) do
        @diagram.add_period(period_label: '2024', events: [' '])
      end
    end

    def test_serialization_deserialization
      @diagram.set_title('Social Media History')
      @diagram.add_section('Early Days')
      @diagram.add_period(period_label: '2002', events: 'LinkedIn')
      @diagram.add_period(period_label: '2004', events: ['Facebook', 'Google'])
      @diagram.add_section('Growth Phase')
      @diagram.add_period(period_label: '2005', events: 'YouTube')
      @diagram.add_period(period_label: '2006', events: 'Twitter')

      original_checksum = @diagram.checksum
      json_data = @diagram.to_json
      reloaded_diagram = TimelineDiagram.from_json(json_data)

      assert_instance_of TimelineDiagram, reloaded_diagram
      assert_equal @diagram.version, reloaded_diagram.version
      assert_equal @diagram.title, reloaded_diagram.title
      assert_equal @diagram.sections.size, reloaded_diagram.sections.size
      assert_equal original_checksum, reloaded_diagram.checksum

      # Deep check structure
      assert_equal 'Early Days', reloaded_diagram.sections[0].title
      assert_equal 2, reloaded_diagram.sections[0].periods.size
      assert_equal '2004', reloaded_diagram.sections[0].periods[1].label
      assert_equal 2, reloaded_diagram.sections[0].periods[1].events.size
      assert_equal 'Facebook', reloaded_diagram.sections[0].periods[1].events[0].description

      assert_equal 'Growth Phase', reloaded_diagram.sections[1].title
      assert_equal 1, reloaded_diagram.sections[1].periods[1].events.size
      assert_equal 'Twitter', reloaded_diagram.sections[1].periods[1].events[0].description
    end

    def test_identifiable_elements
      @diagram.set_title('Test Timeline')
      @diagram.add_section('Section 1')
      p1 = @diagram.add_period(period_label: 'P1', events: 'E1')
      @diagram.add_section('Section 2')
      p2 = @diagram.add_period(period_label: 'P2', events: 'E2')
      p3 = @diagram.add_period(period_label: 'P3', events: 'E3')

      elements = @diagram.identifiable_elements

      assert_equal 2, elements.keys.size
      assert elements.key?(:sections)
      assert elements.key?(:periods)

      assert_equal @diagram.sections, elements[:sections]
      assert_equal [p1, p2, p3], elements[:periods]
    end

    # --- Diffing Tests ---

    def test_diff_identical
      diagram1 = TimelineDiagram.new(title: 'T')
      diagram1.add_section('S1')
      diagram1.add_period(period_label: 'P1', events: 'E1')

      diagram2 = TimelineDiagram.new(title: 'T')
      diagram2.add_section('S1')
      diagram2.add_period(period_label: 'P1', events: 'E1')

      assert_empty diagram1.diff(diagram2)
    end

    def test_diff_added_section
      diagram1 = TimelineDiagram.new(title: 'T')
      diagram1.add_section('S1')

      diagram2 = TimelineDiagram.new(title: 'T')
      diagram2.add_section('S1')
      section2 = diagram2.add_section('S2') # Added

      diff = diagram1.diff(diagram2)
      assert_equal 1, diff.size
      assert diff.key?(:sections)
      assert diff[:sections].key?(:added)
      assert_equal [section2], diff[:sections][:added]
      refute diff[:sections].key?(:removed)
      refute diff[:sections].key?(:modified)
    end

    def test_diff_removed_section
      diagram1 = TimelineDiagram.new(title: 'T')
      diagram1.add_section('S1') # Keep S1
      section2 = diagram1.add_section('S2') # Removed

      diagram2 = TimelineDiagram.new(title: 'T')
      diagram2.add_section('S1')

      diff = diagram1.diff(diagram2)
      assert_equal 1, diff.size
      assert diff.key?(:sections)
      assert diff[:sections].key?(:removed)
      assert_equal [section2], diff[:sections][:removed]
      refute diff[:sections].key?(:added)
      refute diff[:sections].key?(:modified)
    end

    def test_diff_added_period
      diagram1 = TimelineDiagram.new(title: 'T')
      diagram1.add_section('S1')
      diagram1.add_period(period_label: 'P1', events: 'E1')

      diagram2 = TimelineDiagram.new(title: 'T')
      diagram2.add_section('S1')
      diagram2.add_period(period_label: 'P1', events: 'E1')
      period2 = diagram2.add_period(period_label: 'P2', events: 'E2') # Added

      diff = diagram1.diff(diagram2)
      # Adding a period modifies the section AND adds a period element
      assert_equal 2, diff.size
      assert diff.key?(:periods)
      assert diff[:periods].key?(:added)
      assert_equal [period2], diff[:periods][:added]

      assert diff.key?(:sections)
      assert diff[:sections].key?(:modified)
      assert_equal 1, diff[:sections][:modified].size
      mod = diff[:sections][:modified].first
      assert_equal diagram1.sections[0], mod[:old]
      assert_equal diagram2.sections[0], mod[:new]
    end

    def test_diff_removed_period
      diagram1 = TimelineDiagram.new(title: 'T')
      diagram1.add_section('S1')
      diagram1.add_period(period_label: 'P1', events: 'E1')
      period2 = diagram1.add_period(period_label: 'P2', events: 'E2') # Removed

      diagram2 = TimelineDiagram.new(title: 'T')
      diagram2.add_section('S1')
      diagram2.add_period(period_label: 'P1', events: 'E1')

      diff = diagram1.diff(diagram2)
      # Removing a period modifies the section AND removes a period element
      assert_equal 2, diff.size
      assert diff.key?(:periods)
      assert diff[:periods].key?(:removed)
      assert_equal [period2], diff[:periods][:removed]

      assert diff.key?(:sections)
      assert diff[:sections].key?(:modified)
      assert_equal 1, diff[:sections][:modified].size
      mod = diff[:sections][:modified].first
      assert_equal diagram1.sections[0], mod[:old]
      assert_equal diagram2.sections[0], mod[:new]
    end

    def test_diff_modified_period_event # Basic modification check
      diagram1 = TimelineDiagram.new(title: 'T')
      diagram1.add_section('S1')
      period1_v1 = diagram1.add_period(period_label: 'P1', events: 'E1')

      diagram2 = TimelineDiagram.new(title: 'T')
      diagram2.add_section('S1')
      period1_v2 = diagram2.add_period(period_label: 'P1', events: 'E1-changed') # Same label, different event

      diff = diagram1.diff(diagram2)
      # Modifying an event modifies the period, which modifies the section
      assert_equal 2, diff.size
      assert diff.key?(:periods)
      assert diff[:periods].key?(:modified)
      assert_equal 1, diff[:periods][:modified].size
      period_mod = diff[:periods][:modified].first
      assert_equal period1_v1, period_mod[:old]
      assert_equal period1_v2, period_mod[:new]

      assert diff.key?(:sections)
      assert diff[:sections].key?(:modified)
      assert_equal 1, diff[:sections][:modified].size
      section_mod = diff[:sections][:modified].first
      assert_equal diagram1.sections[0], section_mod[:old]
      assert_equal diagram2.sections[0], section_mod[:new]
    end
  end
end