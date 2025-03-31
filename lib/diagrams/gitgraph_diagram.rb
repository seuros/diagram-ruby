# frozen_string_literal: true

require 'digest' # For generating default commit IDs if needed

module Diagrams
  # Represents a Gitgraph diagram, tracking commits, branches, and their relationships.
  class GitgraphDiagram < Base
    attr_reader :commits, :branches, :commit_order, :current_branch_name

    # Initializes a new GitgraphDiagram.
    # Starts with a 'master' branch by default.
    #
    # @param version [String, Integer, nil] User-defined version identifier.
    def initialize(version: 1)
      super
      @commits = {} # Hash { commit_id => GitCommit }
      @branches = {} # Hash { branch_name => GitBranch }
      @commit_order = [] # Array<String> - IDs of commits in order of creation/operation
      @current_branch_name = 'master'

      # Initialize main branch conceptually. Its start/head commit will be set by the first commit.
      # We need a placeholder start_commit_id; using a special value or handling nil in GitBranch might be better.
      # For now, let's use a placeholder that signifies it's the root.
      # A better approach might be to create the branch *during* the first commit. Let's refine this.
      # --> Refinement: Don't create the branch object here. Create it during the first 'commit' or 'branch' operation.
      #                 Initialize @current_branch_name = 'master' conceptually.

      update_checksum! # Initial checksum for an empty graph
    end

    # --- Git Operations ---

    # Adds a commit to the current branch.
    # Handles the creation of the initial 'master' branch on the first commit.
    #
    # @param id [String, nil] Optional custom ID for the commit. Auto-generated if nil.
    # @param message [String, nil] Optional commit message.
    # @param tag [String, nil] Optional tag for the commit.
    # @param type [Symbol] Type of the commit (:NORMAL, :REVERSE, :HIGHLIGHT).
    # @raise [ArgumentError] if a commit with the given ID already exists.
    # @return [Elements::GitCommit] The created commit object.
    def commit(id: nil, message: nil, tag: nil, type: :NORMAL)
      parent_id = current_head_commit_id
      parent_ids = parent_id ? [parent_id] : []

      commit_id = id || generate_commit_id(parent_ids, message)
      raise ArgumentError, "Commit with ID '#{commit_id}' already exists" if @commits.key?(commit_id)

      # Handle first commit: create the master branch
      if @commits.empty? && @current_branch_name == 'master' && !@branches.key?('master')
        # The first commit *is* the starting point of the master branch
        master_branch = Elements::GitBranch.new(name: 'master', start_commit_id: commit_id, head_commit_id: commit_id)
        @branches['master'] = master_branch
      elsif !@branches.key?(@current_branch_name)
        # This case shouldn't typically happen if branch/checkout is used correctly,
        # but defensively handle committing to a non-existent branch (other than initial master).
        raise ArgumentError, "Cannot commit: Branch '#{@current_branch_name}' does not exist."
      end

      new_commit = Elements::GitCommit.new(
        id: commit_id,
        parent_ids:,
        branch_name: @current_branch_name,
        message:,
        tag:,
        type:
      )

      @commits[commit_id] = new_commit
      @commit_order << commit_id

      # Update the head of the current branch
      current_branch = @branches[@current_branch_name]
      current_branch.attributes[:head_commit_id] = commit_id # Update using Dry::Struct's way if needed, direct assign might work

      update_checksum!
      new_commit
    end

    # Creates a new branch pointing to a specific commit (or the current head)
    # and switches the current context to the new branch.
    #
    # @param name [String] The name for the new branch.
    # @param start_commit_id [String, nil] Optional ID of the commit where the branch should start.
    #                                     Defaults to the head commit of the current branch.
    # @raise [ArgumentError] if the branch name already exists or if trying to branch before any commits exist.
    # @raise [ArgumentError] if a specified `start_commit_id` does not exist.
    # @return [Elements::GitBranch] The created branch object.
    def branch(name:, start_commit_id: nil)
      raise ArgumentError, "Branch name '#{name}' already exists" if @branches.key?(name)

      effective_start_commit_id = start_commit_id || current_head_commit_id

      # Ensure there's a commit to branch from
      raise ArgumentError, 'Cannot create a branch before the first commit' unless effective_start_commit_id

      unless @commits.key?(effective_start_commit_id)
        raise ArgumentError,
              "Start commit ID '#{effective_start_commit_id}' does not exist"
      end

      new_branch = Elements::GitBranch.new(
        name:,
        # The new branch initially points to the commit it was created from
        start_commit_id: effective_start_commit_id,
        head_commit_id: effective_start_commit_id
      )

      @branches[name] = new_branch
      @current_branch_name = name # Switch to the new branch

      update_checksum!
      new_branch
    end

    # Switches the current context to an existing branch.
    #
    # @param name [String] The name of the branch to switch to.
    # @raise [ArgumentError] if the branch name does not exist.
    # @return [String] The name of the branch checked out.
    def checkout(name:)
      raise ArgumentError, "Branch '#{name}' does not exist. Cannot checkout." unless @branches.key?(name)

      @current_branch_name = name
      # NOTE: Checkout does not change the diagram structure itself (commits/branches),
      # so we do NOT update the checksum here.
      name
    end

    # Merges the head of a specified branch into the current branch.
    # Creates a merge commit on the current branch.
    #
    # @param from_branch_name [String] The name of the branch to merge from.
    # @param id [String, nil] Optional custom ID for the merge commit. Auto-generated if nil.
    # @param tag [String, nil] Optional tag for the merge commit.
    # @param type [Symbol] Type of the merge commit (defaults to :MERGE, can be overridden e.g., :REVERSE).
    # @raise [ArgumentError] if `from_branch_name` does not exist, is the same as the current branch,
    #                        or if either branch has no commits.
    # @raise [ArgumentError] if a commit with the given ID already exists.
    # @return [Elements::GitCommit] The created merge commit object.
    def merge(from_branch_name:, id: nil, tag: nil, type: :MERGE)
      if from_branch_name == @current_branch_name
        raise ArgumentError,
              "Cannot merge branch '#{from_branch_name}' into itself"
      end
      unless @branches.key?(from_branch_name)
        raise ArgumentError,
              "Branch '#{from_branch_name}' does not exist. Cannot merge."
      end
      unless @branches.key?(@current_branch_name)
        raise ArgumentError, "Current branch '#{@current_branch_name}' does not exist. Cannot merge."
      end

      target_branch = @branches[@current_branch_name]
      source_branch = @branches[from_branch_name]

      target_head_id = target_branch.head_commit_id
      source_head_id = source_branch.head_commit_id

      unless target_head_id
        raise ArgumentError,
              "Current branch '#{@current_branch_name}' has no commits to merge into."
      end
      raise ArgumentError, "Source branch '#{from_branch_name}' has no commits to merge from." unless source_head_id

      # Merge commit parents are the heads of the two branches being merged
      parent_ids = [target_head_id, source_head_id].sort # Sort for consistent checksumming/comparison

      merge_commit_id = id || generate_commit_id(parent_ids,
                                                 "Merge branch '#{from_branch_name}' into #{@current_branch_name}")
      raise ArgumentError, "Commit with ID '#{merge_commit_id}' already exists" if @commits.key?(merge_commit_id)

      merge_commit = Elements::GitCommit.new(
        id: merge_commit_id,
        parent_ids:,
        branch_name: @current_branch_name, # Merge commit belongs to the target branch
        message: "Merge branch '#{from_branch_name}' into #{@current_branch_name}", # Default message
        tag:,
        type: # Use provided type, default :MERGE
      )

      @commits[merge_commit_id] = merge_commit
      @commit_order << merge_commit_id

      # Update the head of the current (target) branch
      target_branch.attributes[:head_commit_id] = merge_commit_id

      update_checksum!
      merge_commit
    end

    # Cherry-picks an existing commit onto the current branch.
    # Creates a new commit on the current branch that mirrors the specified commit.
    #
    # @param commit_id [String] The ID of the commit to cherry-pick.
    # @param parent_override_id [String, nil] Optional: If cherry-picking a merge commit, specifies which parent lineage to follow.
    #                                         (Note: Basic implementation might ignore this for simplicity initially).
    # @raise [ArgumentError] if the commit_id does not exist, is already on the current branch,
    #                        or if the current branch has no commits.
    # @return [Elements::GitCommit] The created cherry-pick commit object.
    # Basic implementation ignores parent_override_id for now
    def cherry_pick(commit_id:, parent_override_id: nil)
      unless @commits.key?(commit_id)
        raise ArgumentError,
              "Commit with ID '#{commit_id}' does not exist. Cannot cherry-pick."
      end

      source_commit = @commits[commit_id]
      current_branch_head_id = current_head_commit_id

      unless current_branch_head_id
        raise ArgumentError,
              "Current branch '#{@current_branch_name}' has no commits. Cannot cherry-pick onto it."
      end
      if source_commit.branch_name == @current_branch_name
        raise ArgumentError,
              "Commit '#{commit_id}' is already on the current branch '#{@current_branch_name}'. Cannot cherry-pick."
      end

      # More robust check: walk history? For now, simple branch name check.

      # TODO: Handle cherry-picking merge commits and parent_override_id if needed later.
      if source_commit.parent_ids.length > 1 && !parent_override_id
        warn "Cherry-picking a merge commit (#{commit_id}) without specifying a parent override is ambiguous. Picking first parent lineage by default."
        # Or raise ArgumentError: "Cherry-picking a merge commit requires specifying parent_override_id."
      end

      parent_ids = [current_branch_head_id] # Cherry-pick commit's parent is the current head
      new_commit_id = generate_commit_id(parent_ids, "Cherry-pick: #{source_commit.message || source_commit.id}")
      if @commits.key?(new_commit_id)
        raise ArgumentError,
              "Generated commit ID '#{new_commit_id}' conflicts with existing commit."
      end

      cherry_pick_commit = Elements::GitCommit.new(
        id: new_commit_id,
        parent_ids:,
        branch_name: @current_branch_name,
        message: source_commit.message || "Cherry-pick of #{source_commit.id}", # Copy message or use default
        tag: nil, # Cherry-picks usually don't copy tags directly
        type: :CHERRY_PICK,
        cherry_pick_source_id: commit_id # Link back to the original commit
      )

      @commits[new_commit_id] = cherry_pick_commit
      @commit_order << new_commit_id

      # Update the head of the current branch
      current_branch = @branches[@current_branch_name]
      current_branch.attributes[:head_commit_id] = new_commit_id

      update_checksum!
      cherry_pick_commit
    end

    # --- Base Class Implementation ---

    # Returns the specific content of the gitgraph diagram as a hash.
    # @return [Hash]
    def to_h_content
      {
        commits: @commits.values.map(&:to_h),
        branches: @branches.values.map(&:to_h),
        commit_order: @commit_order,
        current_branch_name: @current_branch_name # Useful for resuming state? Maybe not needed in content hash.
        # Consider if current_branch_name should be part of the checksummable content.
        # For now, let's include it for potential deserialization needs.
      }
    end

    # Returns a hash mapping element types to their collections for diffing.
    # @return [Hash{Symbol => Array<Elements::GitCommit | Elements::GitBranch>}]
    def identifiable_elements
      {
        commits: @commits.values,
        branches: @branches.values
      }
    end

    # Class method to create a GitgraphDiagram from a hash.
    # @param data_hash [Hash] Hash containing diagram data.
    # @param version [String, Integer, nil] Diagram version.
    # @param checksum [String, nil] Expected checksum (optional).
    # @return [GitgraphDiagram] The instantiated diagram.
    def self.from_h(data_hash, version:, checksum:)
      diagram = new(version:)

      # Restore commits
      commits_data = data_hash[:commits] || data_hash['commits'] || []
      commits_data.each do |commit_h|
        # Convert type back to symbol if it's a string
        commit_data = commit_h.transform_keys(&:to_sym)
        commit_data[:type] = commit_data[:type].to_sym if commit_data[:type].is_a?(String)
        commit = Elements::GitCommit.new(commit_data)
        diagram.commits[commit.id] = commit
      end

      # Restore branches
      branches_data = data_hash[:branches] || data_hash['branches'] || []
      branches_data.each do |branch_h|
        branch = Elements::GitBranch.new(branch_h.transform_keys(&:to_sym))
        diagram.branches[branch.name] = branch
      end

      # Restore commit order
      diagram.instance_variable_set(:@commit_order, data_hash[:commit_order] || data_hash['commit_order'] || [])

      # Restore current branch name
      diagram.instance_variable_set(:@current_branch_name,
                                    data_hash[:current_branch_name] || data_hash['current_branch_name'] || 'master')

      # Recalculate checksum after loading all data
      diagram.send(:update_checksum!) # Use send to call protected method from class scope

      # Optional: Verify checksum if provided
      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded GitgraphDiagram (version: #{version}). Expected #{checksum}, got #{diagram.checksum}."
      end

      diagram
    end

    private

    # Generates a unique ID for a commit if one isn't provided.
    # Placeholder - could use SHA1/SHA256 of content or simple counter.
    # Using a simple counter based on commit order for now.
    def generate_commit_id(parent_ids, message)
      # Simple approach: use commit count + part of parent hash if available
      base = @commit_order.size.to_s
      parent_part = parent_ids.first ? parent_ids.first[0..5] : 'root'
      # NOTE: This is NOT cryptographically secure or git-like. Just for basic uniqueness.
      "commit-#{base}-#{parent_part}-#{Digest::SHA1.hexdigest(message || Time.now.to_s)[0..5]}"
    end

    # Helper to get the head commit ID of the current branch.
    def current_head_commit_id
      current_branch = @branches[@current_branch_name]
      current_branch&.head_commit_id # Returns nil if branch doesn't exist yet
    end

    # Protected method access for from_h
    protected :update_checksum!
  end
end
