# frozen_string_literal: true

module Diagrams
  # Items grouped in titled sections (Gantt tasks, timeline periods). Items go
  # to the last section; an item added before any section opens an untitled
  # one, and only that leading section may be untitled. Item keys are unique
  # across sections. A refused section or item leaves the diagram unchanged.
  module Sectioned
    private

    def open_section(type, member, title, items)
      raise ArgumentError, 'only the first section can be untitled' if title.nil? && sections.any?

      items.each_with_index { |item, index| refuse_duplicate(member, item, items.first(index)) }
      append(:sections, type.new(title:, member => items))
    end

    def add_to_section(type, member, item)
      refuse_duplicate(member, item)
      section = sections.last || append(:sections, type.new)
      replace(:sections, section, section.with(member => [*section.public_send(member), item]))
      item
    end

    def refuse_duplicate(member, item, pending = [])
      return unless [*sections.flat_map(&member), *pending].any? { it.key == item.key }

      raise ArgumentError, "#{item.class.name.split('::').last} #{item.key.inspect} already exists"
    end
  end
end
