# frozen_string_literal: true

module Diagrams
  module Comparable
    def ==(other)
      other.class == self.class && other.state == state
    end
    alias eql? ==

    def hash
      state.hash
    end

    protected

    def state
      instance_variables.map { |name| instance_variable_get(name) }
    end
  end
end
