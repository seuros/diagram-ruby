# frozen_string_literal: true

require 'test_helper'

class TimelineDiagramTest < Minitest::Test
  def setup
    @diagram = Diagrams::TimelineDiagram.new(title: 'Social media')
  end

  def test_periods_go_to_the_last_section
    @diagram.add_period(label: '2002', events: ['LinkedIn'])
    @diagram.add_section(title: 'Later', periods: [{ label: '2004', events: %w[Facebook Google] }])
    @diagram.add_period(label: '2005', events: ['YouTube'])

    assert_equal [nil, 'Later'], @diagram.sections.map(&:title)
    assert_equal %w[2002 2004 2005], @diagram.periods.map(&:label)
    assert_equal %w[Facebook Google], @diagram.periods[1].events
  end

  def test_period_labels_are_unique
    @diagram.add_period(label: '2002', events: ['LinkedIn'])

    assert_error(ArgumentError, /TimelinePeriod "2002" already exists/) do
      @diagram.add_period(label: '2002', events: ['Friendster'])
    end
  end

  def test_only_the_first_section_can_be_untitled
    @diagram.add_section(title: 'A')

    assert_error(ArgumentError, /only the first section can be untitled/) { @diagram.add_section(title: nil) }
  end

  def test_round_trip
    @diagram.add_period(label: '2002', events: ['LinkedIn'])
    @diagram.add_section(title: 'Later', periods: [{ label: '2004', events: ['Facebook'] }])

    assert_round_trip(@diagram)
  end
end
