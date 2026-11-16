# frozen_string_literal: true

module Diagrams
  # Labelled slices of a whole.
  class PieDiagram < Base
    collection :slices, add: :add_slice

    def add_slice(label:, value:) = append(:slices, Elements::Slice.new(label:, value:))

    def total = slices.sum(&:value)

    # Each slice's share of the total, in percent, rounded to two decimals.
    def percentages
      slices.to_h { [it.label, total.zero? ? 0.0 : (it.value * 100.0 / total).round(2)] }
    end
  end
end
