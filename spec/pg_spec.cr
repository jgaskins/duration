require "./spec_helper"
require "db"
require "pg"

require "../src/pg"

pg = DB.open("postgres:///")

describe "Postgres integration" do
  it "converts a Duration to a Postgres INTERVAL type and back" do
    # Postgres only has µs precision, so don't test more granularly than that
    duration = Duration.new(months: 3, days: 10, microseconds: 1)

    queried = pg.query_one <<-SQL, [duration.to_postgres], as: Duration
      SELECT duration
      FROM unnest($1::interval[]) AS subscriptions(duration)
      SQL

    queried.should eq duration
  end

  it "handles being used in DB::Serializable" do
    # See the `Subscription` struct definition below
    subscription = pg.query_one <<-SQL, as: Subscription
      SELECT
        gen_random_uuid() AS id,
        '1 month'::interval AS billing_interval,
        now() AS created_at
      SQL

    subscription.billing_interval.should eq 1.calendar_month
  end
end

struct Subscription
  include DB::Serializable

  getter id : UUID
  getter billing_interval : Duration
  getter created_at : Time
end
