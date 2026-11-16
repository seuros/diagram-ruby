# frozen_string_literal: true

module Diagrams
  class GitgraphDiagram < Base
    # What Mermaid's gitGraph refuses, checked in Mermaid's order, before a
    # merge or cherry-pick changes anything. On top of Mermaid: a cherry-pick
    # is never picked or named as a parent, since Mermaid gives it an id the
    # program cannot name.
    module Refusals
      private

      def refuse_merge(branch, current, other)
        refuse_self_merge(branch, current, other)
        raise ArgumentError, "branch #{current_branch.inspect} has no commits" unless current

        find!(:branches, branch, 'branch')
        raise ArgumentError, "branch #{branch.inspect} has no commits" unless other
        return unless current.id == other.id

        raise ArgumentError, "#{branch.inspect} and #{current_branch.inspect} are both at #{current.id.inspect}"
      end

      def refuse_self_merge(branch, current, other)
        if current && other && current.branch == branch
          raise ArgumentError, "cannot merge branch #{branch.inspect} into itself: " \
                               "its head is the head of #{current_branch.inspect}"
        end
        raise ArgumentError, "cannot merge branch #{branch.inspect} into itself" if branch == current_branch
      end

      def refuse_cherry_pick(source, parent)
        if source.type == :CHERRY_PICK
          raise ArgumentError,
                "#{source.id.inspect} is a cherry-pick, which Mermaid cannot name, so it cannot be picked"
        end

        refuse_parent(source, parent) unless parent.nil?
        if source.type == :MERGE && parent.nil?
          raise ArgumentError, "#{source.id.inspect} is a merge: name the parent to cherry-pick from"
        end
        if source.branch == current_branch
          raise ArgumentError,
                "#{source.id.inspect} is already on #{current_branch.inspect}"
        end
        raise ArgumentError, "branch #{current_branch.inspect} has no commits" if head_id.nil?
      end

      def refuse_parent(source, parent)
        Check.string(parent, :parent)
        unless source.parents.include?(parent)
          raise ArgumentError, "#{parent.inspect} is not an immediate parent of #{source.id.inspect}"
        end
        return unless commit_at(parent).type == :CHERRY_PICK

        raise ArgumentError, "#{parent.inspect} is a cherry-pick, which Mermaid cannot name as a parent"
      end
    end
  end
end
