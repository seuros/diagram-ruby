# frozen_string_literal: true

module Diagrams
  module Plot
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def plottable?
        true
      end
    end

    def plottable?
      self.class.plottable?
    end

    def plot
      raise NotImplementedError
    end
  end
end
