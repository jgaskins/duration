require "pg/result_set"
require "pg/interval"

require "./duration"

module PG
  struct Interval
    def to_duration
      Duration.new(
        months: months,
        days: days,
        nanoseconds: microseconds * 1_000,
      )
    end
  end

  class ResultSet
    def read(t : Duration.class)
      read(Interval).to_duration
    end

    def read(t : Duration?.class)
      read(Interval?).try &.duration
    end
  end
end
