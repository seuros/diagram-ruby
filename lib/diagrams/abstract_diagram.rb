# frozen_string_literal: true

module Diagrams
  # Abstract class for diagrams
  class AbstractDiagram < Dry::Struct
    module Types
      include Dry.Types()
    end

    def initialize(*)
      raise NotImplementedError, 'Cannot instantiate abstract class' if instance_of?(AbstractDiagram)

      super
    end

    def type
      raise NotImplementedError, 'Subclasses must define `type`.'
    end

    class << self
      def from_hash(hash)
        new(deep_symbolize_keys(hash))
      end

      def from_json(json)
        from_hash(JSON.parse(json))
      end

      private

      def deep_symbolize_keys(hash)
        hash.each_with_object({}) do |(key, value), memo|
          memo[key.to_sym] = value.is_a?(Hash) ? deep_symbolize_keys(value) : value
        end
      end
    end
  end

  ## Errors
  class ValidationError < StandardError; end
  class EmptyDiagramError < ValidationError; end
  class DuplicateLabelError < ValidationError; end
end
