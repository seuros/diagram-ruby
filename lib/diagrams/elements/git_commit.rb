# frozen_string_literal: true

module Diagrams
  module Elements
    # A commit on +branch_name+. +parent_ids+ lists the first parent (the
    # branch's previous head) first. A merge has two parents and names the
    # branch it merged; a cherry-pick names the commit it copied.
    GitCommit = Data.define(:id, :branch_name, :parent_ids, :message, :tag, :type,
                            :merge_branch_name, :cherry_pick_source_id) do
      include Element

      def initialize(id:, branch_name:, parent_ids: [], message: nil, tag: nil, type: :NORMAL,
                     merge_branch_name: nil, cherry_pick_source_id: nil)
        super(
          id: Check.string(id, :id),
          branch_name: Check.string(branch_name, :branch_name),
          parent_ids: Check.strings(parent_ids, :parent_ids),
          message: Check.optional_string(message, :message),
          tag: Check.optional_string(tag, :tag),
          type: Check.symbol(type, :type, GitCommit::TYPES),
          merge_branch_name: Check.optional_string(merge_branch_name, :merge_branch_name),
          cherry_pick_source_id: Check.optional_string(cherry_pick_source_id, :cherry_pick_source_id)
        )
      end

      def key = id
    end

    GitCommit::TYPES = %i[NORMAL REVERSE HIGHLIGHT MERGE CHERRY_PICK].freeze
  end
end
