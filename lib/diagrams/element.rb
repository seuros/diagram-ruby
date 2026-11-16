# frozen_string_literal: true

module Diagrams
  # Behaviour shared by every element. Elements are Data values: built from
  # keywords, checked on construction (and by #with), compared by value.
  module Element
    def self.included(base) = base.extend(ClassMethods)

    # Class-level construction from a hash.
    module ClassMethods
      # Builds the element from a hash of its members (string or symbol keys).
      def from_h(hash) = new(**Check.symbolize(hash))
    end

    # The element's identity within its collection, or nil when only its
    # whole value identifies it (edges, transitions, relationships).
    def key = nil

    # Members as plain data, nested elements included, nil members left out.
    def to_h = super.filter_map { |name, value| [name, dump(value)] unless value.nil? }.to_h

    private

    def dump(value)
      case value
      when Element then value.to_h
      when Array then value.map { dump(it) }
      else value
      end
    end
  end
end
