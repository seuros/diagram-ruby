# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a branch in a Gitgraph diagram.
    class GitBranch < Dry::Struct
      include Elements::Types

      attribute :name, Types::Strict::String.constrained(min_size: 1)
      # head_commit_id can be nil initially if the branch is created before any commits
      attribute :head_commit_id, Types::Strict::String.optional.default(nil)
      attribute :start_commit_id, Types::Strict::String.constrained(min_size: 1)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String}]
      def to_h
        hash = {
          name:,
          start_commit_id:
        }
        hash[:head_commit_id] = head_commit_id if head_commit_id
        hash
      end
    end
  end
end
