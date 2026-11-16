# frozen_string_literal: true

require 'date'

module Diagrams
  class GanttDiagram < Base
    # Mermaid's gantt date arithmetic (dayjs on JavaScript dates), in UTC
    # milliseconds on the proleptic Gregorian calendar:
    # - days and weeks: whole days, the count rounded as Math.round does;
    # - months and years: the integer part of current + n, from day 1, then
    #   the day clamped to the month's length;
    # - h, m, s, ms: milliseconds added, the sum truncated.
    # Dates and results must stay within years 0100 to 9999, where Mermaid's
    # arithmetic is exact; anything else is refused. Beyond 9999 it stops
    # being exact (and soon silently gives a zero length). Below 0100 dayjs
    # builds dates with JavaScript's Date constructor, which reads years 0-99
    # as 1900-1999: Mermaid then rejects end dates (the task collapses to its
    # start) and clamps months by the wrong year's February.
    module Calendar
      DAY = 86_400_000
      STEPS = { 'h' => 3_600_000, 'm' => 60_000, 's' => 1000, 'ms' => 1 }.freeze
      EPOCH = Date.new(1970, 1, 1, Date::GREGORIAN).jd
      FIRST_YEAR = 100
      LAST_YEAR = 9999

      module_function

      def date(text) = from_civil(*text.split('-').map(&:to_i))

      def valid_date?(text) = Date.valid_date?(*text.split('-').map(&:to_i), Date::GREGORIAN)

      # +time+ plus a Mermaid length such as "3d" or "1.5h".
      def add(time, length)
        number, unit = length.match(/\A(\d+(?:\.\d+)?)(ms|[Mdhmswy])\z/).captures
        # 10**15 ms is past year 9999 already: longer numbers cannot fit.
        raise ArgumentError, "length #{length.inspect} is beyond Mermaid's dates" if number[/\A\d+/].sub(/\A0+(?=\d)/,
                                                                                                         '').size > 15

        number = Float(number)

        case unit
        when 'd' then time + (round(number) * DAY)
        when 'w' then time + (round(7 * number) * DAY)
        when 'M' then shift_month(time, number)
        when 'y' then shift_year(time, number)
        else (time + (number * STEPS.fetch(unit))).truncate
        end
      end

      def check(time, what)
        return time if time.between?(from_civil(FIRST_YEAR, 1, 1), from_civil(LAST_YEAR + 1, 1, 1) - 1)

        raise ArgumentError, "#{what} falls outside years 0100-9999, where Mermaid's dates are exact"
      end

      def to_time(time) = Time.at(*time.divmod(1000), :millisecond, in: 'UTC')

      # JavaScript's Math.round: halves round up.
      def round(number)
        floor = number.floor
        number - floor >= 0.5 ? floor + 1 : floor
      end

      def shift_month(time, number)
        year, month, day, rest = civil(time)
        months = ((month - 1) + number).truncate
        clamp(year + months.div(12), (months % 12) + 1, day, rest)
      end

      def shift_year(time, number)
        _, month, day, rest = civil(time)
        clamp((civil(time).first + number).truncate, month, day, rest)
      end

      def clamp(year, month, day, rest)
        last = Date.new(year, month, -1, Date::GREGORIAN).day
        from_civil(year, month, [day, last].min) + rest
      end

      def civil(time)
        days, rest = time.divmod(DAY)
        date = Date.jd(EPOCH + days, Date::GREGORIAN)
        [date.year, date.month, date.day, rest]
      end

      def from_civil(year, month, day) = (Date.new(year, month, day, Date::GREGORIAN).jd - EPOCH) * DAY
    end
  end
end
