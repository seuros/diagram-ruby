# frozen_string_literal: true

module Diagrams
  module Elements
    # A Gantt task. +start+ is a date or "after <task id>"; +duration+ is a
    # length such as "3d" or an end date.
    Task = Data.define(:id, :label, :start, :duration, :status) do
      include Element

      def initialize(id:, label:, start:, duration:, status: nil)
        super(
          id: Check.string(id, :id),
          label: Check.string(label, :label),
          start: Check.string(start, :start),
          duration: Check.string(duration, :duration),
          status: status && Check.symbol(status, :status, Task::STATUSES)
        )
      end

      def key = id
    end

    Task::STATUSES = %i[done active crit milestone].freeze
  end
end
