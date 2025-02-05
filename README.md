# Duration

This shard allows you to represent both monotonic and calendar durations in a single struct.

The three ways to track durations of time with the `Duration` type are:

1. Calendar Months
2. Calendar Days
3. Monotonic time with nanosecond precision

### Calendar Months

Months can be anywhere from 28-31 days. Tracking calendar months with `Duration` is similar to the `Time::MonthSpan` in the Crystal stdlib, but with extra functionality.

### Calendar days

It's easy to think of a day as 24 hours, but due to Daylight Savings Time, days can be anywhere from 23-25 hours long. `Duration` is great for when you need to measure things in calendar days and not necessarily 24-hour chunks.

### Monotonic time

Monotonic time is what the Crystal stdlib `Time::Span` measures. `Duration` doesn't have the same capacity as `Time::Span`, but it still gives you about 300 years of monotonic time to play with.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     duration:
       github: jgaskins/duration
   ```

2. Run `shards install`

## Usage

```crystal
require "duration"

duration = Duration.new(months: 12, days: 34, nanoseconds: 5678)

years = Duration.new(years: 3)
years = 3.calendar_years

months = Duration.new(months: 6)
months = 6.calendar_months

weeks = Duration.new(weeks: 3)
weeks = 3.calendar_weeks

days = Duration.new(days: 20)
days = 20.calendar_days

monotonic = Duration.new(hours: 6, minutes: 35, seconds: 10)
```

Monotonic durations don't have a method you can add onto `Number` like the calendar units do, but you can use methods that generate `Time::Span` instances and then call `to_duration` on them:

```crystal
duration = 1.hour.to_duration
```

You can also convert the monotonic portion of a `Duration` instance to a `Time::Span`:

```crystal
span = Duration.new(hours: 3).to_span
```

> [!IMPORTANT]
> Only the monotonic portion (the value returned by `nanoseconds`) is used in this conversion. `Time::Span` does not have a way to measure calendar days. If you would like to consider calendar days as 24-hour increments, you will need to pass `include_days: true`. Days are not included by default because they are not guaranteed to be 24 hours, for example across DST boundaries.

```crystal
duration = Duration.new(days: 2, hours: 3)

span = duration.to_span(include_days: true)
```

Time math is also supported:

```crystal
Time.utc + Duration.new(years: 1, months: 4, weeks: 6, days: 3, hours: 12, minutes: 34, seconds: 56)
```

### Using with Postgres

You can also decode `Duration` instances from Postgres directly. Let's say you have a model for subscriptions, which can have variable durations:

```crystal
# Load the Postgres integration
require "duration/pg"

struct Subscription
  include DB::Serializable

  getter id : UUID
  # Using a Duration type defined by this shard.
  getter duration : Duration
end
```

Now we can query our table and return `Duration` instances without a `@[DB::Field]` annotation with a `converter`.

```crystal
# Connect to Postgres
pg = DB.open("postgres:///")

# Return a result set with a UUID and an INTERVAL type
sql = <<-SQL
  SELECT
    gen_random_uuid() AS id,
    '1 month'::interval AS duration
  FROM generate_series(1, 2)
  SQL

# When we iterate over our results, we'll get our Subscription struct above.
pg.query_each sql do |rs|
  pp Subscription.new rs
end
```

## Contributing

1. Fork it (<https://github.com/jgaskins/duration/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jamie Gaskins](https://github.com/jgaskins) - creator and maintainer
