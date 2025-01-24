require "db"
require "pg"
require "../src/duration"
require "../src/pg"

pg = DB.open("postgres:///")

struct Subscription
  include DB::Serializable

  getter id : UUID
  getter duration : Duration
end

require "benchmark"

sql = <<-SQL
  SELECT
    gen_random_uuid() id,
    interval '1 month' duration
  FROM generate_series(1, 2)
  SQL

pg.query_each sql do |rs|
  pp Subscription.new rs
end
