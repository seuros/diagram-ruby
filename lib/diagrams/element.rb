# frozen_string_literal: true

module Diagrams
  # Behaviour shared by every element. Elements are Data values: built from
  # keywords, checked on construction (and by #with), compared by value.
  # Marshal goes through the same checks: an element dumps its members as
  # JSON and loads by rebuilding itself from them.
  module Element
    def self.included(base) = base.extend(ClassMethods)

    # Class-level construction from a hash.
    module ClassMethods
      # Builds the element from a hash of its members (string or symbol keys).
      def from_h(hash) = new(**Check.symbolize(Check.record(hash, name)))

      def _load(json) = from_h(JSON.parse(json))
    end

    # The element's identity within its collection. Elements without a key
    # (edges, transitions, relationships) are identified by their whole
    # value, and may repeat.
    def key = nil

    def keyed? = method(:key).owner != Element

    # Members as plain data, nested elements included, nil members left out.
    def to_h = super.filter_map { |name, value| [name, dump(value)] unless value.nil? }.to_h

    def _dump(_level) = JSON.generate(to_h)

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
