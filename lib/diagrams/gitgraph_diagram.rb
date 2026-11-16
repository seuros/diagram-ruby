# frozen_string_literal: true

module Diagrams
  # A git history built by replaying git operations: commit, branch, checkout,
  # merge and cherry_pick. The main branch appears with the first commit.
  # Which branch is checked out is editing state, not content: a diagram
  # loaded with .from_h starts on the main branch.
  class GitgraphDiagram < Base
    COMMIT_TYPES = %i[NORMAL REVERSE HIGHLIGHT].freeze

    collection :commits
    collection :branches

    attr_reader :main_branch, :current_branch_name

    def initialize(main_branch: 'main', **)
      super(**)
      @main_branch = Check.string(main_branch, :main_branch)
      @current_branch_name = @main_branch
    end

    def commit(id: nil, message: nil, tag: nil, type: :NORMAL)
      add_commit(id:, message:, tag:, type: Check.symbol(type, :type, COMMIT_TYPES), parent_ids: [head_id].compact)
    end

    # Creates a branch at +start_commit_id+ (default: the current head) and checks it out.
    def branch(name:, start_commit_id: head_id)
      raise ArgumentError, 'cannot branch before the first commit' if start_commit_id.nil?

      find!(:commits, start_commit_id, 'commit')
      append(:branches, Elements::GitBranch.new(name:, start_commit_id:)).tap { @current_branch_name = it.name }
    end

    def checkout(name:) = @current_branch_name = find!(:branches, name, 'branch').name

    # Merges +from_branch_name+ into the current branch with a merge commit.
    def merge(from_branch_name:, id: nil, tag: nil)
      source = find!(:branches, from_branch_name, 'branch')
      raise ArgumentError, "cannot merge #{source.name.inspect} into itself" if source.name == current_branch_name
      if source.head_commit_id == head_id
        raise ArgumentError, "#{source.name.inspect} and #{current_branch_name.inspect} are both at #{head_id.inspect}"
      end

      add_commit(id:, tag:, type: :MERGE, parent_ids: [head_id, source.head_commit_id],
                 message: "Merge branch '#{source.name}' into #{current_branch_name}",
                 merge_branch_name: source.name)
    end

    # Copies a commit from another branch onto the current one.
    def cherry_pick(commit_id:, id: nil)
      source = find!(:commits, commit_id, 'commit')
      raise ArgumentError, "cannot cherry-pick merge commit #{commit_id.inspect}" if source.type == :MERGE
      if source.branch_name == current_branch_name
        raise ArgumentError, "commit #{commit_id.inspect} is already on #{current_branch_name.inspect}"
      end

      add_commit(id:, message: source.message, type: :CHERRY_PICK, parent_ids: [head_id],
                 cherry_pick_source_id: source.id)
    end

    class << self
      private

      # Replays the commits in order. Branches are created in their recorded
      # order, each as soon as its start commit exists.
      def restore(data, version:)
        new(version:, **data.except(:commits, :branches)).tap do |diagram|
          pending = records(data, :branches).reject { it[:name] == diagram.main_branch }
          records(data, :commits).each do |commit|
            open_branches(diagram, pending)
            diagram.checkout(name: commit[:branch_name]) unless diagram.commits.empty?
            replay(diagram, commit)
          end
          open_branches(diagram, pending)
          diagram.checkout(name: diagram.main_branch) unless diagram.commits.empty?
          raise ArgumentError, "branch #{pending.first[:name].inspect} starts at no known commit" if pending.any?
          unless diagram.commits == recorded(data, :commits, Elements::GitCommit) &&
                 diagram.branches == recorded(data, :branches, Elements::GitBranch)
            raise ArgumentError, 'commits and branches do not replay to the recorded history'
          end
        end
      end

      def recorded(data, name, type) = records(data, name).map { type.from_h(it) }

      def records(data, name) = Check.list(data.fetch(name, []), name).map { Check.record(it, name) }

      def open_branches(diagram, pending)
        while (branch = pending.first) && diagram.commits.any? { it.id == branch[:start_commit_id] }
          diagram.branch(**pending.shift.slice(:name, :start_commit_id))
        end
      end

      def replay(diagram, commit)
        case commit[:type].nil? ? :NORMAL : Check.symbol(commit[:type], :type, Elements::GitCommit::TYPES)
        when :MERGE then diagram.merge(from_branch_name: commit[:merge_branch_name], **commit.slice(:id, :tag))
        when :CHERRY_PICK then diagram.cherry_pick(commit_id: commit[:cherry_pick_source_id], id: commit[:id])
        else diagram.commit(**commit.slice(:id, :message, :tag, :type))
        end
      end
    end

    private

    def settings = { **super, main_branch: }

    def head_id = branches.find { it.name == current_branch_name }&.head_commit_id

    def add_commit(id:, **)
      commit = append(:commits,
                      Elements::GitCommit.new(id: id.nil? ? next_id : id, branch_name: current_branch_name, **))
      current = branches.find { it.name == current_branch_name }
      if current
        replace(:branches, current, current.with(head_commit_id: commit.id))
      else
        append(:branches, Elements::GitBranch.new(name: main_branch, start_commit_id: commit.id))
      end
      commit
    end

    def next_id
      number = commits.size
      number += 1 while commits.any? { it.id == "commit-#{number}" }
      "commit-#{number}"
    end
  end
end
