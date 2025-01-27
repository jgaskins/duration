require "db"
require "pg"

require "./duration"

struct Duration
  def to_postgres
    String.build { |str| to_postgres str }
  end

  def to_postgres(io) : Nil
    if zero?
      io << "0 seconds"
    else
      io << months << " months " if months > 0
      io << days << " days " if days > 0
      io << microseconds << " microseconds" if nanoseconds >= 1_000
    end
  end
end

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
