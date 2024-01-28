# frozen_string_literal: true

module Diagrams
  class PieDiagram < AbstractDiagram
    attribute :id, Types::String.optional.default(nil)
    attribute :title, Types::String.optional.default('')
    attribute :sections, Types::Array.of(Section).optional.default([].freeze)

    def type
      :pie
    end

    def validate!
      raise EmptyDiagramError, 'Pie diagram must have at least one section' if sections.empty?
      # raise InvalidPercentageError, 'Pie diagram sections must sum to 100%' unless sections.map(&:percentage).sum == 100

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
        puts "#{section.label}: #{section.percentage}%"
      end
    end

    def valid?
      validate!
    end
  end
end
