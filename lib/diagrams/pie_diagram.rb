# frozen_string_literal: true

module Diagrams
  # Labelled slices of a whole.
  class PieDiagram < Base
    collection :slices, add: :add_slice

    # The total must stay a finite Float: a slice that would overflow it is
    # refused with RangeError.
    def add_slice(label:, value:)
      slice = Elements::Slice.new(label:, value:)
      raise RangeError, 'the total of the slices must stay finite' unless (total + slice.value).to_f.finite?

      append(:slices, slice)
    end

    def total = slices.sum(&:value)

    # Each slice's share of the total, in percent, rounded to two decimals.
    # Computed exactly, so values near the Float limit do not overflow.
    def percentages
      exact = slices.sum { it.value.to_r }
      slices.to_h { [it.label, exact.zero? ? 0.0 : (it.value.to_r * 100 / exact).round(2).to_f] }
    end
  end
end
