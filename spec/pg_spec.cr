require "./spec_helper"
require "db"
require "pg"

require "../src/pg"

pg = DB.open("postgres:///")

describe "Postgres integration" do
  it "converts a Duration to a Postgres INTERVAL type and back" do
    duration = Duration.new(months: 3, days: 10, microseconds: 1)

    queried = pg.query_one <<-SQL, [duration.to_postgres], as: Duration
      SELECT duration
      FROM unnest($1::interval[]) AS subscriptions(duration)
      SQL

    queried.should eq duration
  end
end
