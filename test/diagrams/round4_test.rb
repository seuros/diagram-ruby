# frozen_string_literal: true

require 'test_helper'

# Regressions from the fourth review: Mermaid misreads years 0000-0099, so
# Gantt dates start at 0100. Each refusal below was a silent mismatch.
class Round4Test < Minitest::Test
  # dayjs clamps months by 1900-1999's February: 0000-01-31 + 1M is 0000-02-28.
  def test_month_clamping_before_year_0100_is_refused
    [%w[0000-01-31 1M], %w[0000-02-29 0M]].each do |start, duration|
      gantt = Diagrams::GanttDiagram.new

      assert_error(ArgumentError, /task "t" start falls outside years 0100-9999/) do
        gantt.add_task(id: 't', label: 'T', start:, duration:)
      end
      assert_empty gantt.tasks
    end
  end

  # dayjs rejects these end dates, so Mermaid collapses the task to its start
  # and every task after it moves too.
  def test_end_dates_before_year_0100_are_refused
    %w[0000 0001 0004 0099].each do |year|
      gantt = Diagrams::GanttDiagram.new

      assert_error(ArgumentError, /task "t" start falls outside years 0100-9999/) do
        gantt.add_task(id: 't', label: 'T', start: "#{year}-01-01", duration: "#{year}-02-01")
      end
      assert_error(ArgumentError, /unknown tasks t/) do
        gantt.add_task(id: 'next', label: 'N', start: 'after t', duration: '1d')
      end
      assert_empty gantt.tasks
    end
  end

  def test_a_finish_below_year_0100_is_refused
    gantt = Diagrams::GanttDiagram.new

    assert_error(ArgumentError, /task "t" end falls outside years 0100-9999/) do
      gantt.add_task(id: 't', label: 'T', start: '0100-01-01', duration: '0099-12-31')
    end
    assert_empty gantt.tasks
  end

  def test_years_0100_to_9999_are_placed_as_mermaid_places_them
    gantt = Diagrams::GanttDiagram.new
    gantt.add_task(id: 'first', label: 'F', start: '0100-01-01', duration: '0100-02-01')
    gantt.add_task(id: 'month', label: 'M', start: '0100-01-31', duration: '1M')
    gantt.add_task(id: 'next', label: 'N', start: 'after first', duration: '1d')
    gantt.add_task(id: 'back', label: 'B', start: 'after next', duration: 'until first')
    gantt.add_task(id: 'last', label: 'L', start: '9999-12-31', duration: '86399999ms')

    assert_equal({ 'first' => [Time.utc(100, 1, 1), Time.utc(100, 2, 1)],
                   'month' => [Time.utc(100, 1, 31), Time.utc(100, 2, 28)],
                   'next' => [Time.utc(100, 2, 1), Time.utc(100, 2, 2)],
                   'back' => [Time.utc(100, 2, 2), Time.utc(100, 1, 1)],
                   'last' => [Time.utc(9999, 12, 31), Time.utc(9999, 12, 31, 23, 59, Rational(59_999, 1000))] },
                 gantt.schedule.transform_values { [it.begin, it.end] })
  end
end
