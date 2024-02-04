# frozen_string_literal: true

require 'test_helper'
module Diagrams
  class PieDiagramTest < DiagramTest
    def test_initialize
      sections = create_sections
      diagram = create_pie_diagram(sections)

      assert_equal 'Pie Diagram', diagram.title
      assert_equal 2, diagram.sections.size
      assert_predicate diagram, :valid?
    end

    def test_to_json
      sections = create_sections
      diagram = create_pie_diagram(sections)

      expected = { title: 'Pie Diagram',
                   type: 'pie',
                   sections: }

      assert_equal expected, diagram.to_json
    end

    def test_from_json
      sections = create_sections
      diagram_json = deep_stringify_keys(
        { title: 'Pie Diagram',
          type: 'pie',
          sections: }
      )
      diag = PieDiagram.from_hash(diagram_json)

      assert_equal 'Pie Diagram', diag.title
    end

    def test_type
      assert_equal 'pie', PieDiagram.new({}).type
    end

    def test_add_remove_section
      diagram = PieDiagram.new({})
      section = diagram.add_section(id: '1', label: 'Section 1', value: 30)

      assert_equal 1, diagram.sections.size
      assert_equal 'Section 1', diagram.sections.first.label
      assert_equal 30, diagram.sections.first.value
      assert_equal section, diagram.sections.first

      diagram.remove_section('1')

      assert_equal 0, diagram.sections.size
    end

    private

    def create_sections
      [{
        id: '1',
        label: 'Section 1', value: 30
      }, {
        id: '2',
        label: 'Section 2', value: 40
      }]
    end

    def create_pie_diagram(sections)
      PieDiagram.new(
        title: 'Pie Diagram',
        sections:
      )
    end
  end
end
