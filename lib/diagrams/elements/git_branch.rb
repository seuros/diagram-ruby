# frozen_string_literal: true

module Diagrams
  module Elements
    # A branch: the commit it starts from and its current head.
    GitBranch = Data.define(:name, :start_commit_id, :head_commit_id) do
      include Element

      def initialize(name:, start_commit_id:, head_commit_id: start_commit_id)
        super(
          name: Check.string(name, :name),
          start_commit_id: Check.string(start_commit_id, :start_commit_id),
          head_commit_id: Check.string(head_commit_id, :head_commit_id)
        )
      end

      def key = name
    end
  end
end
