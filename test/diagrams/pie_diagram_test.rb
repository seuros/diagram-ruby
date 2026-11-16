# frozen_string_literal: true

require 'test_helper'

class PieDiagramTest < Minitest::Test
  def setup
    @diagram = Diagrams::PieDiagram.new(title: 'Pets')
    @diagram.add_slice(label: 'Dogs', value: 3)
    @diagram.add_slice(label: 'Cats', value: 1.5)
  end

  def test_total_and_percentages
    assert_in_delta 4.5, @diagram.total
    assert_equal({ 'Dogs' => 66.67, 'Cats' => 33.33 }, @diagram.percentages)
  end

  def test_percentages_of_nothing
    diagram = Diagrams::PieDiagram.new
    diagram.add_slice(label: 'None', value: 0)

    assert_equal({ 'None' => 0.0 }, diagram.percentages)
  end

  def test_duplicate_labels_are_rejected
    assert_error(ArgumentError, /Slice "Dogs" already exists/) { @diagram.add_slice(label: 'Dogs', value: 1) }
  end

  def test_round_trip
    assert_round_trip(@diagram)
  end
end
