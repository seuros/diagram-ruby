# frozen_string_literal: true

module Diagrams
  # Items grouped in titled sections (Gantt tasks, timeline periods). Items go
  # to the last section; an item added before any section opens an untitled
  # one, and only that leading section may be untitled. Item keys are unique
  # across sections.
  module Sectioned
    private

    def open_section(type, title, items)
      raise ArgumentError, 'only the first section can be untitled' if title.nil? && sections.any?

      append(:sections, type.new(title:))
      items.each { yield it.to_h }
      sections.last
    end

    def add_to_section(type, member, item)
      if sections.flat_map(&member).any? { it.key == item.key }
        raise ArgumentError, "#{item.class.name.split('::').last} #{item.key.inspect} already exists"
      end

      section = sections.last || append(:sections, type.new)
      replace(:sections, section, section.with(member => [*section.public_send(member), item]))
      item
    end
  end
end
