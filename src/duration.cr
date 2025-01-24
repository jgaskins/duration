# TODO: Write documentation for `Duration`
struct Duration
  VERSION = "0.1.0"

  getter months : Int32
  getter days : Int32
  getter nanoseconds : Int64

  def self.new(span : Time::Span)
    new nanoseconds: span.total_nanoseconds.to_i64
  end

  def self.new(month_span : Time::MonthSpan)
    new months: month_span.value.to_i32
  end

  def self.new(month_span : Time::MonthSpan, span : Time::Span)
    new(month_span) + new(span)
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
    @nanoseconds = 0i64,
  )
    @months += years * 12
    @days += weeks * 7
    minutes += hours * 60
    seconds += minutes * 60
    @nanoseconds += seconds * 1_000_000_000
  end

  def hours : Float64
    minutes / 60
  end

  def minutes : Float64
    seconds / 60
  end

  def seconds : Float64
    nanoseconds / 1_000_000_000
  end

  def weeks : Float64
    days / 7
  end

  def years : Float64
    months / 12
  end

  def +(other : self) : self
    self.class.new(
      months: months + other.months,
      days: days + other.days,
      nanoseconds: nanoseconds + other.nanoseconds,
    )
  end

  def -(other : self) : self
    self.class.new(
      months: months - other.months,
      days: days - other.days,
      nanoseconds: nanoseconds - other.nanoseconds,
    )
  end

  def *(factor : Int) : self
    self.class.new(
      months: months * factor,
      days: days * factor,
      nanoseconds: nanoseconds * factor,
    )
  end

  def //(factor : Int) : self
    self.class.new(
      months: months // factor,
      days: days // factor,
      nanoseconds: nanoseconds // factor,
    )
  end

  def from_now(location = Time::Location.local)
    from Time.local(location)
  end

  def from(time : Time)
    time + self
  end

  def ago(location = Time::Location.local)
    before Time.local(location)
  end

  def before(time : Time)
    time - self
  end

  def to_span
    days.days + nanoseconds.nanoseconds
  end

  def to_month_span
    months.months
  end
end

struct Time
  def +(duration : Duration) : Time
    shift(months: duration.months, days: duration.days) + duration.nanoseconds.nanoseconds
  end

  def -(duration : Duration) : Time
    shift(months: -duration.months, days: -duration.days) - duration.nanoseconds.nanoseconds
  end

  struct Span
    def to_duration
      ::Duration.new(self)
    end
  end

  struct MonthSpan
    def to_duration
      ::Duration.new(self)
    end
  end
end

struct Int
  def calendar_day
    calendar_days
  end

  def calendar_days
    Duration.new(days: to_i32)
  end

  def calendar_month
    calendar_months
  end

  def calendar_months
    Duration.new(months: to_i32)
  end
end
