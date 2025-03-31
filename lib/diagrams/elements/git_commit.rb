# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a commit in a Gitgraph diagram.
    class GitCommit < Dry::Struct
      include Elements::Types

      attribute :id, Types::Strict::String.constrained(min_size: 1)
      attribute :parent_ids, Types::Strict::Array.of(Types::Strict::String).default([].freeze)
      attribute :branch_name, Types::Strict::String.constrained(min_size: 1)
      attribute :message, Types::Strict::String.optional.default(nil)
      attribute :tag, Types::Strict::String.optional.default(nil)
      attribute :type, Types::Strict::Symbol.default(:NORMAL).enum(:NORMAL, :REVERSE, :HIGHLIGHT, :MERGE, :CHERRY_PICK)
      attribute :cherry_pick_source_id, Types::Strict::String.optional.default(nil)

      # Returns a hash representation suitable for serialization.
      # Dry::Struct provides to_h, but explicit definition ensures desired keys/structure.
      # Optional attributes are included only if they have non-nil values.
      #
      # @return [Hash{Symbol => String | Array<String> | Symbol}]
      def to_h
        hash = {
          id:,
          parent_ids:,
          branch_name:,
          type:
        }
        hash[:message] = message if message
        hash[:tag] = tag if tag
        hash[:cherry_pick_source_id] = cherry_pick_source_id if cherry_pick_source_id
        hash
      end
    end
  end
end
