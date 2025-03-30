require "./parser/iso8601"

# The `Duration` type represents calendar months, calendar days, and monotonic
# time spans, allowing for more precise temporal math.
struct Duration
  VERSION = "0.1.0"

  getter months : Int32
  getter days : Int32
  getter nanoseconds : Int64

  # Instantiate a `Duration` from a `Time::Span`.
  #
  # ```
  # Duration.new(5.seconds)
  # # => Duration(@months=0, @days=0, @nanoseconds=5000000000)
  # ```
  def self.new(span : Time::Span)
    new nanoseconds: span.total_nanoseconds.to_i64
  end

  # Instantiate a `Duration` from a `Time::MonthSpan`.
  #
  # ```
  # Duration.new(6.months)
  # # => Duration(@months=6, @days=0, @nanoseconds=0)
  # ```
  def self.new(month_span : Time::MonthSpan)
    new months: month_span.value.to_i32
  end

  # Instantiate a `Duration` from both a `Time::MonthSpan` and a `Time::Span`.
  #
  # ```
  # Duration.new(5.seconds)
  # # => Duration(@months=0, @days=0, @nanoseconds=5000000000)
  # ```
  #
  # NOTE: While you can get months and monotonic time, there is no way to get
  # calendar days from this constructor.
  def self.new(month_span : Time::MonthSpan, span : Time::Span)
    new(month_span) + new(span)
  end

  # Parse [ISO8601 duration strings](https://en.wikipedia.org/wiki/ISO_8601#Durations) 
  # like `"P3Y6M4DT12H30M5S"` into `Duration` instances.
  #
  # ```
  # # 3 years, 6 months, 4 days, 12 hours, 30 minutes, 5.5 seconds
  # Duration.parse_iso8601("P3Y6M4DT12H30M5.5S")
  # # => Duration(@months=42, @days=4, @nanoseconds=45005500000000)
  # ```
  #
  # The parser is incredibly efficient and performs no heap allocations.
  def self.parse_iso8601(string : String)
    Parser::ISO8601.new.parse string
  end

  def initialize(
    *,
    years : Int32 = 0,
    @months : Int32 = 0,
    weeks : Int64 = 0,
    @days = 0,
    hours : Int64 = 0i64,
    minutes : Int64 = 0i64,
    seconds : Int64 = 0i64,
    milliseconds : Int64 = 0i64,
    microseconds : Int64 = 0i64,
    @nanoseconds = 0i64,
  )
    @months += years * 12
    @days += weeks * 7
    minutes += hours * 60
    seconds += minutes * 60
    milliseconds += seconds * 1_000
    microseconds += milliseconds * 1_000
    @nanoseconds += microseconds * 1_000
  end

  # Returns monotonic hours, including the fractional part.
  #
  # ```
  # Duration.new(hours: 3, minutes: 30).hours # => 3.5
  # ```
  def hours : Float64
    minutes / 60
  end

  # Returns monotonic minutes, including the fractional part.
  #
  # ```
  # Duration.new(minutes: 3, seconds: 30).minutes # => 3.5
  # ```
  def minutes : Float64
    seconds / 60
  end

  # Returns monotonic seconds, including the fractional part.
  #
  # ```
  # Duration.new(milliseconds: 15_500).seconds # => 15.5
  # ```
  def seconds : Float64
    nanoseconds / 1_000_000_000
  end

  # Returns monotonic milliseconds, including the fractional part.
  #
  # ```
  # Duration.new(microseconds: 15_500).milliseconds # => 15.5
  # ```
  def milliseconds : Float64
    nanoseconds / 1_000_000
  end

  # Returns monotonic microseconds, including the fractional part.
  #
  # ```
  # Duration.new(nanoseconds: 15_500).microseconds # => 15.5
  # ```
  def microseconds : Float64
    nanoseconds / 1_000
  end

  # Returns the number of calendar weeks represented by this `Duration`, including the fractional part
  #
  # ```
  # Duration.new(days: 45).weeks # => 6.428571428571429
  # ```
  def weeks : Float64
    days / 7
  end

  # Returns the number of calendar years represented by this `Duration`, including the fractional part
  #
  # ```
  # Duration.new(months: 45).years # => 3.75
  # ```
  def years : Float64
    months / 12
  end

  # Returns `true` if this `Duration` does not measure any time at all, `false`
  # otherwise.
  def zero?
    months.zero? && days.zero? && nanoseconds.zero?
  end

  # Add a `Time::Span` a `Time::MonthSpan` from the crystal standard library to this `Duration`. The `Time::Span` will be added to the monotonic portion of this `Duration` and the `Time::MonthSpan` will be added to the `months` portion.
  #
  # ```
  # Duration.new(years: 1) + 1.month + 1.hour
  # # => Duration(@months=13, @days=0, @nanoseconds=3600000000000)
  # ```
  def +(other : Time::Span | Time::MonthSpan) : self
    self + other.to_duration
  end

  # Returns the sum of two `Duration` instances.
  def +(other : self) : self
    self.class.new(
      months: months + other.months,
      days: days + other.days,
      nanoseconds: nanoseconds + other.nanoseconds,
    )
  end

  # Subtract a `Time::Span` or `Time::MonthSpan` (from the crystal standard
  # library) to this `Duration`. The `Time::Span` will be subtracted from the
  # monotonic portion of this `Duration` and the `Time::MonthSpan` will be
  # subtracted from the `months` portion.
  def -(other : Time::Span | Time::MonthSpan) : self
    self - other.to_duration
  end

  # Returns the difference between two `Duration` instances.
  def -(other : self) : self
    self.class.new(
      months: months - other.months,
      days: days - other.days,
      nanoseconds: nanoseconds - other.nanoseconds,
    )
  end

  # Multiplies this `Duration` by the given factor.
  def *(factor : Int) : self
    self.class.new(
      months: months * factor,
      days: days * factor,
      nanoseconds: nanoseconds * factor,
    )
  end

  # Divides this `Durtation` by the given scalar. Note that only integer division is supported.
  def //(factor : Int) : self
    self.class.new(
      months: months // factor,
      days: days // factor,
      nanoseconds: nanoseconds // factor,
    )
  end

  # Returns the time that this `Duration` represents from the current local time.
  #
  # ```
  # 1.calendar_day.from_now
  # ```
  def from_now(location = Time::Location.local)
    from Time.local(location)
  end

  # Returns the time that this `Duration` represents from the given time.
  #
  # ```
  # next_bill_at = 1.calendar_month.from(subscription.last_billed_at)
  # ```
  def from(time : Time)
    time + self
  end

  # Returns the time that this `Duration` represents before the current local time.
  #
  # ```
  # 1.calendar_day.ago
  # ```
  def ago(location = Time::Location.local)
    before Time.local(location)
  end

  # Returns the time that this `Duration` represents before the given time.
  #
  # ```
  # previous_run = 1.calendar_day.before(next_scheduled_run)
  # ```
  def before(time : Time)
    time - self
  end

  # Return the monotonic portion of this `Duration` as a Crystal stdlib
  # `Time::Span` instance.
  #
  # NOTE: Since the Crystal stdlib has no representation of calendar days, it is
  # not currently possible to incorporate the concept of calendar days. If you
  # are comfortable with approximating the number of days as 24 monotonic hours
  # you can pass `include_days: true`, however keep in mind that this may return
  # an incorrect value when performing arithmetic on a `Duration` and a `Time`
  # crosses a daylight savings boundary.
  def to_span(include_days = false)
    span = nanoseconds.nanoseconds
    if include_days
      span += days.days
    end

    span
  end

  # Return the month portion of this `Duration` as a Crystal stdlib
  # `Time::MonthSpan` instance.
  def to_month_span
    months.months
  end

  # Output an ISO8601 representation of this `Duration` to the given `IO`
  def to_iso8601 : String
    String.build { |str| to_iso8601 str }
  end

  def to_iso8601(io : IO) : Nil
    io << "P"
    if months > 0
      years, months = self.months.divmod 12
      io << years << 'Y' if years > 0
      io << months << 'M' if months > 0
    end
    io << days << 'D' if days > 0
    if nanoseconds > 0
      io << 'T'
      minutes, nanoseconds = self.nanoseconds.divmod 60_000_000_000i64
      hours, minutes = minutes.divmod 60
      seconds = nanoseconds / 1_000_000_000
      int_seconds = seconds.to_i64
      if seconds == int_seconds
        seconds = int_seconds
      end
      io << hours << 'H' if hours > 0
      io << minutes << 'M' if minutes > 0
      io << seconds << 'S' if seconds > 0
    end
  end
end

struct Time
  # Return a new `Time` instance that is ahead of this `Time` by the amount of time specified in `Duration`.
  def +(duration : Duration) : Time
    shift(months: duration.months, days: duration.days) + duration.nanoseconds.nanoseconds
  end

  # Return a new `Time` instance that is behind this `Time` by the amount of time specified in `Duration`.
  def -(duration : Duration) : Time
    shift(months: -duration.months, days: -duration.days) - duration.nanoseconds.nanoseconds
  end

  struct Span
    # Convert this `Time::Span` into the monotonic portion of a `Duration`.
    def to_duration
      ::Duration.new(self)
    end
  end

  struct MonthSpan
    # Convert this `Time::MonthSpan` into the calendar-months portion of a `Duration`.
    def to_duration
      ::Duration.new(self)
    end
  end
end

struct Int
  # Convenience method to represent the number of calendar weeks represented by this integer.
  def calendar_week
    calendar_weeks
  end

  # :ditto:
  def calendar_weeks
    (7 * self).calendar_days
  end

  # Convenience method to represent the number of calendar days represented by this integer.
  def calendar_day
    calendar_days
  end

  # :ditto:
  def calendar_days
    Duration.new(days: to_i32)
  end

  # Convenience method to represent the number of calendar years represented by this integer.
  def calendar_year
    calendar_years
  end

  # :ditto:
  def calendar_years
    (12 * self).calendar_months
  end

  # Convenience method to represent the number of calendar months represented by this integer.
  def calendar_month
    calendar_months
  end

  # :ditto:
  def calendar_months
    Duration.new(months: to_i32)
  end
end
