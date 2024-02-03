# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class PieDiagramTest < DiagramTest
    def test_initialize
      diagram = PieDiagram.new(
        title: 'Pie Diagram',
        sections: [{
          label: 'Section 1',
          value: 30
        },
                   {
                     label: 'Section 2',
                     value: 40
                   }]
      )

      assert_equal 'Pie Diagram', diagram.title
      assert_equal 2, diagram.sections.size
      assert_predicate diagram, :valid?
    end

    def test_type
      assert_equal :pie, PieDiagram.new({}).type
    end
  end
end
