# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class GitgraphDiagramTest < Minitest::Test
    def setup
      # Setup runs before each test
      @diagram = GitgraphDiagram.new
    end

    def test_initialization
      assert_instance_of GitgraphDiagram, @diagram
      assert_empty @diagram.commits
      assert_empty @diagram.branches # Branches are created on first commit/branch op
      assert_empty @diagram.commit_order
      assert_equal 'master', @diagram.current_branch_name
      refute_nil @diagram.checksum
    end

    def test_first_commit_creates_master_branch
      commit1 = @diagram.commit(id: 'C1', message: 'Initial commit')

      assert_equal 1, @diagram.commits.size
      assert_equal 1, @diagram.branches.size
      assert @diagram.branches.key?('master')

      master_branch = @diagram.branches['master']

      assert_equal 'master', master_branch.name
      assert_equal 'C1', master_branch.start_commit_id
      assert_equal 'C1', master_branch.head_commit_id

      assert_equal commit1, @diagram.commits['C1']
      assert_equal ['C1'], @diagram.commit_order
      assert_equal 'master', @diagram.current_branch_name
    end

    def test_subsequent_commits_on_master
      @diagram.commit(id: 'C1', message: 'Initial commit')
      commit2 = @diagram.commit(id: 'C2', message: 'Second commit')

      assert_equal 2, @diagram.commits.size
      assert_equal 1, @diagram.branches.size # Still only main branch

      master_branch = @diagram.branches['master']

      assert_equal 'C2', master_branch.head_commit_id # Head updated

      assert_equal commit2, @diagram.commits['C2']
      assert_equal %w[C1 C2], @diagram.commit_order
      assert_equal ['C1'], commit2.parent_ids
    end

    def test_branching
      @diagram.commit(id: 'C1', message: 'Initial commit')
      dev_branch = @diagram.branch(name: 'develop')

      assert_equal 2, @diagram.branches.size
      assert @diagram.branches.key?('develop')
      assert_equal 'develop', @diagram.current_branch_name

      assert_equal 'develop', dev_branch.name
      assert_equal 'C1', dev_branch.start_commit_id
      assert_equal 'C1', dev_branch.head_commit_id # New branch points to start commit initially
    end

    def test_commit_on_new_branch
      @diagram.commit(id: 'C1', message: 'Initial commit')
      @diagram.branch(name: 'develop')
      commit_dev = @diagram.commit(id: 'D1', message: 'Dev commit')

      assert_equal 2, @diagram.commits.size
      assert_equal 2, @diagram.branches.size

      dev_branch = @diagram.branches['develop']

      assert_equal 'D1', dev_branch.head_commit_id

      master_branch = @diagram.branches['master']

      assert_equal 'C1', master_branch.head_commit_id # Master branch head unchanged

      assert_equal commit_dev, @diagram.commits['D1']
      assert_equal %w[C1 D1], @diagram.commit_order
      assert_equal ['C1'], commit_dev.parent_ids
      assert_equal 'develop', commit_dev.branch_name
    end

    def test_checkout
      @diagram.commit(id: 'C1', message: 'Initial commit')
      @diagram.branch(name: 'develop')
      @diagram.commit(id: 'D1', message: 'Dev commit')

      @diagram.checkout(name: 'master')

      assert_equal 'master', @diagram.current_branch_name

      commit_master = @diagram.commit(id: 'C2', message: 'Back on master')

      assert_equal 3, @diagram.commits.size
      assert_equal %w[C1 D1 C2], @diagram.commit_order

      master_branch = @diagram.branches['master']

      assert_equal 'C2', master_branch.head_commit_id

      dev_branch = @diagram.branches['develop']

      assert_equal 'D1', dev_branch.head_commit_id # Dev branch head unchanged

      assert_equal ['C1'], commit_master.parent_ids
      assert_equal 'master', commit_master.branch_name
    end

    def test_merge
      @diagram.commit(id: 'C1')
      @diagram.branch(name: 'develop')
      @diagram.commit(id: 'D1')
      @diagram.checkout(name: 'master')
      @diagram.commit(id: 'C2')
      merge_commit = @diagram.merge(from_branch_name: 'develop', id: 'M1')

      assert_equal 4, @diagram.commits.size
      assert_equal %w[C1 D1 C2 M1], @diagram.commit_order

      assert_equal merge_commit, @diagram.commits['M1']
      assert_equal :MERGE, merge_commit.type
      assert_equal %w[C2 D1], merge_commit.parent_ids.sort # Check both parents, order might vary
      assert_equal 'master', merge_commit.branch_name

      master_branch = @diagram.branches['master']

      assert_equal 'M1', master_branch.head_commit_id # Master branch head is the merge commit
    end

    def test_cherry_pick
      @diagram.commit(id: 'C1')
      @diagram.branch(name: 'feature')
      @diagram.commit(id: 'F1', message: 'Feature commit')
      @diagram.checkout(name: 'master')
      @diagram.commit(id: 'C2')
      cherry_commit = @diagram.cherry_pick(commit_id: 'F1')

      assert_equal 4, @diagram.commits.size
      refute_nil cherry_commit
      assert_equal :CHERRY_PICK, cherry_commit.type
      assert_equal 'F1', cherry_commit.cherry_pick_source_id
      assert_equal ['C2'], cherry_commit.parent_ids
      assert_equal 'master', cherry_commit.branch_name
      assert_equal @diagram.commits['F1'].message, cherry_commit.message # Check message copied

      master_branch = @diagram.branches['master']

      assert_equal cherry_commit.id, master_branch.head_commit_id
    end

    def test_serialization_deserialization
      @diagram.commit(id: 'C1')
      @diagram.branch(name: 'develop')
      @diagram.commit(id: 'D1')
      @diagram.checkout(name: 'master')
      @diagram.commit(id: 'C2')
      @diagram.merge(from_branch_name: 'develop', id: 'M1', tag: 'v1.0-merge')

      original_checksum = @diagram.checksum
      json_data = @diagram.to_json
      reloaded_diagram = GitgraphDiagram.from_json(json_data)

      assert_instance_of GitgraphDiagram, reloaded_diagram
      assert_equal @diagram.version, reloaded_diagram.version
      assert_equal @diagram.commits.keys.sort, reloaded_diagram.commits.keys.sort
      assert_equal @diagram.branches.keys.sort, reloaded_diagram.branches.keys.sort
      assert_equal @diagram.commit_order, reloaded_diagram.commit_order
      assert_equal @diagram.current_branch_name, reloaded_diagram.current_branch_name
      assert_equal original_checksum, reloaded_diagram.checksum

      # Check specific elements
      assert_equal 'v1.0-merge', reloaded_diagram.commits['M1'].tag
      assert_equal :MERGE, reloaded_diagram.commits['M1'].type
      assert_equal %w[C2 D1], reloaded_diagram.commits['M1'].parent_ids.sort
    end

    # --- Error Handling and Edge Cases ---

    def test_commit_duplicate_id
      @diagram.commit(id: 'C1')
      assert_raises(ArgumentError, /Commit with ID 'C1' already exists/) do
        @diagram.commit(id: 'C1')
      end
    end

    def test_branch_duplicate_name
      @diagram.commit(id: 'C1')
      @diagram.branch(name: 'develop')
      assert_raises(ArgumentError, /Branch name 'develop' already exists/) do
        @diagram.branch(name: 'develop')
      end
    end

    def test_branch_before_first_commit
      assert_raises(ArgumentError, /Cannot create a branch before the first commit/) do
        @diagram.branch(name: 'develop')
      end
    end

    def test_branch_from_non_existent_commit
      @diagram.commit(id: 'C1')
      assert_raises(ArgumentError, /Start commit ID 'C_invalid' does not exist/) do
        @diagram.branch(name: 'develop', start_commit_id: 'C_invalid')
      end
    end

    def test_checkout_non_existent_branch
      @diagram.commit(id: 'C1')
      assert_raises(ArgumentError, /Branch 'no_such_branch' does not exist. Cannot checkout./) do
        @diagram.checkout(name: 'no_such_branch')
      end
    end

    def test_merge_non_existent_source_branch
      @diagram.commit(id: 'C1')
      assert_raises(ArgumentError, /Branch 'no_such_branch' does not exist. Cannot merge./) do
        @diagram.merge(from_branch_name: 'no_such_branch')
      end
    end

    def test_merge_into_itself
      @diagram.commit(id: 'C1')
      @diagram.branch(name: 'develop')
      @diagram.checkout(name: 'develop')
      assert_raises(ArgumentError, /Cannot merge branch 'develop' into itself/) do
        @diagram.merge(from_branch_name: 'develop')
      end
    end

    def test_merge_source_branch_no_commits
      # Technically covered by branch creation logic, but explicit test is good
      @diagram.commit(id: 'C1')
      # Create branch but don't commit on it (GitgraphDiagram#branch sets head_commit_id)
      @diagram.branch(name: 'empty_branch') # head is C1
      @diagram.checkout(name: 'master')
      @diagram.commit(id: 'C2')
      # Merge should work as empty_branch points to C1
      assert @diagram.merge(from_branch_name: 'empty_branch')
    end

    def test_merge_target_branch_no_commits
      # This scenario is prevented by the commit logic (first commit creates master)
      # and branch logic (requires a start commit).
      # If we manually create a diagram state where target has no head, it should fail.
      @diagram.commit(id: 'C1')
      @diagram.branch(name: 'develop')
      @diagram.commit(id: 'D1')
      # Manually mess up the state for testing the check
      @diagram.branches['master'].attributes[:head_commit_id] = nil
      assert_raises(ArgumentError, /Current branch 'master' has no commits to merge into./) do
        @diagram.merge(from_branch_name: 'develop')
      end
    end

    def test_merge_duplicate_commit_id
      @diagram.commit(id: 'C1')
      @diagram.branch(name: 'develop')
      @diagram.commit(id: 'D1')
      @diagram.checkout(name: 'master')
      @diagram.commit(id: 'C2')
      @diagram.merge(from_branch_name: 'develop', id: 'M1')
      # Try merging again with same ID
      @diagram.checkout(name: 'develop')
      @diagram.commit(id: 'D2') # Make branches different again
      @diagram.checkout(name: 'master')
      assert_raises(ArgumentError, /Commit with ID 'M1' already exists/) do
        @diagram.merge(from_branch_name: 'develop', id: 'M1')
      end
    end

    def test_cherry_pick_non_existent_commit
      @diagram.commit(id: 'C1')
      assert_raises(ArgumentError, /Commit with ID 'no_such_commit' does not exist. Cannot cherry-pick./) do
        @diagram.cherry_pick(commit_id: 'no_such_commit')
      end
    end

    def test_cherry_pick_onto_empty_branch
      # Prevented by logic - current branch must have a head commit
      @diagram.commit(id: 'C1')
      @diagram.branch(name: 'feature') # feature head is C1
      @diagram.checkout(name: 'master')
      # Manually mess up state
      @diagram.branches['master'].attributes[:head_commit_id] = nil
      assert_raises(ArgumentError, /Current branch 'master' has no commits. Cannot cherry-pick onto it./) do
        @diagram.cherry_pick(commit_id: 'C1') # Try to pick C1 from feature (where it originated)
      end
    end

    def test_cherry_pick_commit_already_on_branch
      # Simple check based on commit.branch_name
      @diagram.commit(id: 'C1')
      @diagram.commit(id: 'C2')
      assert_raises(ArgumentError, /Commit 'C1' is already on the current branch 'master'/) do
        @diagram.cherry_pick(commit_id: 'C1')
      end
    end

    # --- Diffing Tests ---

    def test_diff_identical_diagrams
      diagram1 = GitgraphDiagram.new
      diagram1.commit(id: 'C1')
      diagram1.branch(name: 'dev')
      diagram1.commit(id: 'D1')

      diagram2 = GitgraphDiagram.new
      diagram2.commit(id: 'C1')
      diagram2.branch(name: 'dev')
      diagram2.commit(id: 'D1')

      assert_empty diagram1.diff(diagram2)
      assert_empty diagram2.diff(diagram1)
    end

    def test_diff_added_commit
      diagram1 = GitgraphDiagram.new
      diagram1.commit(id: 'C1')

      diagram2 = GitgraphDiagram.new
      diagram2.commit(id: 'C1')
      commit2 = diagram2.commit(id: 'C2') # Added commit

      diff_result = diagram1.diff(diagram2)
      # Expect added commit AND modified branch head
      assert_equal 2, diff_result.size
      assert diff_result.key?(:commits)
      assert diff_result[:commits].key?(:added)
      assert_equal [commit2], diff_result[:commits][:added]
      refute diff_result[:commits].key?(:removed)
      refute diff_result[:commits].key?(:modified)

      assert diff_result.key?(:branches)
      assert diff_result[:branches].key?(:modified)
      assert_equal 1, diff_result[:branches][:modified].size
      branch_mod = diff_result[:branches][:modified].first

      assert_equal diagram1.branches['master'], branch_mod[:old] # Head was C1
      assert_equal diagram2.branches['master'], branch_mod[:new] # Head is C2
    end

    def test_diff_removed_commit
      diagram1 = GitgraphDiagram.new
      diagram1.commit(id: 'C1')
      commit2 = diagram1.commit(id: 'C2') # This will be removed

      diagram2 = GitgraphDiagram.new
      diagram2.commit(id: 'C1')

      diff_result = diagram1.diff(diagram2)
      # Expect removed commit AND modified branch head
      assert_equal 2, diff_result.size
      assert diff_result.key?(:commits)
      assert diff_result[:commits].key?(:removed)
      assert_equal [commit2], diff_result[:commits][:removed]
      refute diff_result[:commits].key?(:added)
      refute diff_result[:commits].key?(:modified)

      assert diff_result.key?(:branches)
      assert diff_result[:branches].key?(:modified)
      assert_equal 1, diff_result[:branches][:modified].size
      branch_mod = diff_result[:branches][:modified].first

      assert_equal diagram1.branches['master'], branch_mod[:old] # Head was C2
      assert_equal diagram2.branches['master'], branch_mod[:new] # Head is C1
    end

    def test_diff_added_branch
      diagram1 = GitgraphDiagram.new
      diagram1.commit(id: 'C1')

      diagram2 = GitgraphDiagram.new
      diagram2.commit(id: 'C1')
      branch_dev = diagram2.branch(name: 'develop') # Added branch

      diff_result = diagram1.diff(diagram2)

      assert_equal 1, diff_result.size
      assert diff_result.key?(:branches)
      assert diff_result[:branches].key?(:added)
      assert_equal [branch_dev], diff_result[:branches][:added]
      refute diff_result[:branches].key?(:removed)
      refute diff_result[:branches].key?(:modified)
      refute diff_result.key?(:commits)
    end

    def test_diff_removed_branch
      diagram1 = GitgraphDiagram.new
      diagram1.commit(id: 'C1')
      branch_dev = diagram1.branch(name: 'develop') # This will be removed

      diagram2 = GitgraphDiagram.new
      diagram2.commit(id: 'C1')

      diff_result = diagram1.diff(diagram2)

      assert_equal 1, diff_result.size
      assert diff_result.key?(:branches)
      assert diff_result[:branches].key?(:removed)
      assert_equal [branch_dev], diff_result[:branches][:removed]
      refute diff_result[:branches].key?(:added)
      refute diff_result[:branches].key?(:modified)
      refute diff_result.key?(:commits)
    end

    # Basic modification check
    def test_diff_modified_commit_tag
      diagram1 = GitgraphDiagram.new
      commit1_v1 = diagram1.commit(id: 'C1', tag: 'v1')

      diagram2 = GitgraphDiagram.new
      commit1_v2 = diagram2.commit(id: 'C1', tag: 'v2') # Same ID, different tag

      diff_result = diagram1.diff(diagram2)

      assert_equal 1, diff_result.size
      assert diff_result.key?(:commits)
      assert diff_result[:commits].key?(:modified)
      assert_equal 1, diff_result[:commits][:modified].size
      modification = diff_result[:commits][:modified].first

      assert_equal commit1_v1, modification[:old]
      assert_equal commit1_v2, modification[:new]
      refute diff_result[:commits].key?(:added)
      refute diff_result[:commits].key?(:removed)
    end

    # Basic modification check
    def test_diff_modified_branch_head
      diagram1 = GitgraphDiagram.new
      diagram1.commit(id: 'C1')
      diagram1.branch(name: 'develop') # Head is C1

      diagram2 = GitgraphDiagram.new
      diagram2.commit(id: 'C1')
      branch_dev_v2 = diagram2.branch(name: 'develop') # Head is C1 initially
      commit_d1 = diagram2.commit(id: 'D1') # Now head is D1

      diff_result = diagram1.diff(diagram2)
      # The branch object itself changes because head_commit_id changes
      # Expect modified branch AND added commit
      assert_equal 2, diff_result.size
      assert diff_result.key?(:branches)
      assert diff_result[:branches].key?(:modified)
      assert_equal 1, diff_result[:branches][:modified].size
      modification = diff_result[:branches][:modified].first
      # NOTE: branch_dev_v1 object is captured before diagram1 changes further
      # Need to be careful with object identity vs value comparison here.
      # Let's re-fetch the branch from diagram1 for comparison
      assert_equal diagram1.branches['develop'], modification[:old]
      assert_equal branch_dev_v2, modification[:new] # branch_dev_v2 captured after D1 commit
      refute diff_result[:branches].key?(:added)
      refute diff_result[:branches].key?(:removed)

      # Also expect D1 to be added
      assert diff_result.key?(:commits)
      assert diff_result[:commits].key?(:added)
      assert_equal [commit_d1], diff_result[:commits][:added]
    end
  end
end
