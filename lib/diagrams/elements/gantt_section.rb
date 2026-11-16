# frozen_string_literal: true

module Diagrams
  module Elements
    # A group of Gantt tasks. Only the leading section may be untitled.
    GanttSection = Data.define(:title, :tasks) do
      include Element

      def initialize(title: nil, tasks: [])
        super(title: Check.optional_string(title, :title), tasks: Check.elements(tasks, :tasks, Task))
      end

      def key = title
    end
  end
end
