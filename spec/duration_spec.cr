require "./spec_helper"

describe Duration do
  # Just to have a single place we're loading from. It's too tedious to keep
  # writing this.
  eastern = Time::Location.load("America/New_York")

  it "measures nanoseconds" do
    Duration.new(nanoseconds: 123).nanoseconds.should eq 123
    Duration.new(seconds: 123).nanoseconds.should eq 123_000_000_000
  end

  it "measures microseconds" do
    Duration.new(microseconds: 123).microseconds.should eq 123
  end

  it "measures milliseconds" do
    Duration.new(milliseconds: 123).milliseconds.should eq 123
  end

  it "measures seconds" do
    Duration.new(seconds: 123).seconds.should eq 123
    Duration.new(minutes: 123).seconds.should eq 123 * 60
    Duration.new(hours: 123).seconds.should eq 123 * 60 * 60
    Duration.new(milliseconds: 15_500).seconds.should eq 15.5
  end

  it "measures minutes" do
    Duration.new(hours: 3).minutes.should eq 180
  end

  it "measures hours" do
    Duration.new(hours: 3).hours.should eq 3
    Duration.new(hours: 3, minutes: 30).hours.should eq 3.5
  end

  it "measures days" do
    Duration.new(days: 123).days.should eq 123
    Duration.new(weeks: 5).days.should eq 35
  end

  it "measures weeks" do
    Duration.new(days: 123).weeks.should eq 123 / 7
  end

  it "measures months" do
    Duration.new(months: 123).months.should eq 123
    Duration.new(years: 123).months.should eq 123 * 12
  end

  it "measures years" do
    Duration.new(months: 123).years.should eq 123 / 12
    Duration.new(years: 123).years.should eq 123
  end

  it "indicates a zero duration" do
    Duration.new.zero?.should eq true
    Duration.new(nanoseconds: 1).zero?.should eq false
    Duration.new(days: 1).zero?.should eq false
    Duration.new(months: 1).zero?.should eq false
  end

  it "returns a time this far in the future" do
    timestamp = Time.local(2025, 1, 21, location: eastern)

    1.calendar_day.from(timestamp).should eq Time.local(2025, 1, 22, location: eastern)
    1.calendar_day.from_now.should be_within 1.second, of: 1.day.from_now
  end

  it "returns a time this far in the past" do
    timestamp = Time.local(2025, 1, 21, location: eastern)

    1.calendar_day.before(timestamp).should eq Time.local(2025, 1, 20, location: eastern)
    1.calendar_day.ago.should be_within 1.second, of: 1.day.ago
  end

  describe "math with other durations" do
    it "adds two durations together" do
      duration = Duration.new(months: 1, days: 2, seconds: 3) + Duration.new(months: 4, days: 5, seconds: 6)

      duration.months.should eq 5
      duration.days.should eq 7
      duration.seconds.should eq 9
    end

    it "subtracts two durations" do
      duration = Duration.new(months: 6, days: 5, seconds: 4) - Duration.new(months: 1, days: 2, seconds: 3)

      duration.months.should eq 5
      duration.days.should eq 3
      duration.seconds.should eq 1
    end

    it "subtracts a larger duration from a smaller one" do
      duration = Duration.new(months: 1, days: 2, seconds: 3) - Duration.new(months: 6, days: 5, seconds: 4)

      duration.months.should eq -5
      duration.days.should eq -3
      duration.seconds.should eq -1
    end

    it "multiplies a duration by a scalar" do
      (Duration.new(months: 1, days: 2, seconds: 3) * 2).should eq Duration.new(months: 2, days: 4, seconds: 6)
    end

    it "divides by a scalar" do
      (Duration.new(months: 2, days: 4, seconds: 6) // 2).should eq Duration.new(months: 1, days: 2, seconds: 3)
    end
  end

  describe "math with Time::Span and Time::MonthSpan" do
    it "adds Duration + Time::Span" do
      (1.hour.to_duration + 1.hour).should eq 2.hours.to_duration
    end

    it "adds Duration + Time::MonthSpan" do
      (1.year.to_duration + 1.year).should eq 2.years.to_duration

      (Duration.new(years: 1) + 1.month + 1.hour).should eq Duration.new(
        years: 1,
        months: 1,
        hours: 1,
      )
    end

    it "subtracts Duration - Time::Span" do
      (2.hours.to_duration - 1.hour).should eq 1.hour.to_duration
    end

    it "subtracts Duration - Time::MonthSpan" do
      (2.years.to_duration - 1.year).should eq 1.year.to_duration
    end
  end

  describe "math with Time instances" do
    # DST starts at 2am on this date
    time = Time.local(2025, 3, 9, location: eastern)

    it "adds a monotonic Duration to a Time" do
      # Add a monotonic measurement. Since this involves a 1-hour spring-ahead,
      # 24 hours doesn't give the same time the next day. It actually gives the
      # appearance of 25 hours. DST is the fuckin' worst.
      (time + Duration.new(hours: 24)).should eq Time.local(2025, 3, 10, hour: 1, location: eastern)
    end

    it "adds a Duration with calendar days" do
      # Add a calendar day, which *does* return the same time the next day.
      (time + Duration.new(days: 1)).should eq Time.local(2025, 3, 10, location: eastern)
    end

    it "adds a duration with calendar months" do
      # Add a calendar month, which returns the same time on the same day of the next month.
      (time + Duration.new(months: 1)).should eq Time.local(2025, 4, 9, location: eastern)
    end
  end

  describe "creating from Crystal stdlib spans" do
    it "creates from a Time::Span" do
      Duration.new(1.second).seconds.should eq 1
      1.second.to_duration.seconds.should eq 1
    end

    it "creates from a Time::MonthSpan" do
      Duration.new(1.year).months.should eq 12
      1.year.to_duration.months.should eq 12
    end

    it "creates from both a Time::MonthSpan and a Time::Span" do
      duration = Duration.new(1.year, 1.hour)
      duration.months.should eq 12
      duration.minutes.should eq 60
    end
  end

  describe "conversion to Crystal stdlib spans" do
    it "converts the monotonic portion to a Time::Span" do
      Duration.new(1.hour).to_span.should eq 1.hour
    end

    it "converts to a Time::Span excluding calendar days" do
      Duration.new(days: 1, hours: 1).to_span.should eq 1.hour
    end

    it "can include an estimate of the monotonic time using calendar days" do
      Duration.new(days: 1, hours: 1).to_span(include_days: true)
        .should eq 25.hours
    end

    it "converts to a Time::MonthSpan" do
      Duration.new(1.year).to_month_span.should eq 1.year
    end
  end

  describe "parsing from ISO8601 strings" do
    {
      "PT0.001192S"      => Duration.new(microseconds: 1192),
      "P23DT23H"         => Duration.new(days: 23, hours: 23),
      "P4Y"              => Duration.new(years: 4),
      "PT0.5S"           => Duration.new(milliseconds: 500),
      "P1DT12H"          => Duration.new(days: 1, hours: 12),
      "P3Y6M4DT12H30M5S" => Duration.new(
        years: 3,
        months: 6,
        days: 4,
        hours: 12,
        minutes: 30,
        seconds: 5,
      ),
    }.each do |string, duration|
      it "parses #{string} as #{duration}" do
        Duration.parse_iso8601(string).should eq duration
      end
    end
  end

  describe "converting to ISO8601 strings" do
    {
      Duration.new(microseconds: 1192)  => "PT0.001192S",
      Duration.new(days: 23, hours: 23) => "P23DT23H",
      Duration.new(years: 4)            => "P4Y",
      Duration.new(milliseconds: 500)   => "PT0.5S",
      Duration.new(days: 1, hours: 12)  => "P1DT12H",
      Duration.new(
        years: 3,
        months: 6,
        days: 4,
        hours: 12,
        minutes: 30,
        seconds: 5,
      ) => "P3Y6M4DT12H30M5S",
    }.each do |duration, string|
      it "emits #{duration} as #{string.inspect}" do
        duration.to_iso8601.should eq string
      end
    end
  end
end

def be_within(epsilon, of value)
  be_close value, epsilon
end
