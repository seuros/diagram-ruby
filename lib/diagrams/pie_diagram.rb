# frozen_string_literal: true

module Diagrams
  class PieDiagram < AbstractDiagram
    attribute :id, Types::String.optional.default(nil)
    attribute :title, Types::String.optional.default('')
    attribute :sections, Types::Array.of(Section).optional.default([].freeze)

    def type
      'pie'
    end

    def add_section(*args)
      section = Section.new(*args)
      attributes[:sections] = attributes[:sections] + [section]
      section
    end

    def remove_section(section_id)
      attributes[:sections] = attributes[:sections].reject { |section| section.id == section_id }
    end

    def validate!
      raise EmptyDiagramError, 'Pie diagram must have at least one section' if sections.empty?

      return true if sections.map(&:label).uniq.size == sections.size

      raise DuplicateLabelError,
            'Pie diagram sections must have unique labels'
    end

    def plot
      circle_char = '*'
      pie_diameter = 10
      pie_radius = pie_diameter / 2.0

      (-pie_radius.to_i..pie_radius.to_i).each do |i|
        (-pie_radius.to_i..pie_radius.to_i).each do |j|
          distance_to_center = Math.sqrt((i**2) + (j**2))
          if distance_to_center > pie_radius - 0.5 && distance_to_center < pie_radius + 0.5
            print circle_char
          else
            print ' '
          end
        end
        print "\n"
      end

      sections.each do |section|
        puts "#{section.label}: #{section.value}%"
      end
    end

    def to_json(*_args)
      {
        type:,
        title:,
        sections: sections.map(&:to_h)
      }
    end

    def valid?
      validate!
      true
    rescue ValidationError
      false
    end
  end
end
