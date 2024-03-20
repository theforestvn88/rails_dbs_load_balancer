require "active_record"
require "redis"

ENV["RAILS_ENV"] = "test"

config = {
  "test" => {
    "primary"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary.sqlite3", "pool" => 5 },
    "primary_replica1"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica1.sqlite3", "replica" => true, "pool" => 5, "checkout_timeout" => 100 },
    "primary_replica2"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica2.sqlite3", "replica" => true, "pool" => 5, "checkout_timeout" => 100 },
    "primary_replica3"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica3.sqlite3", "replica" => true, "pool" => 5, "checkout_timeout" => 100 },
    "primary_replica4"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica4.sqlite3", "replica" => true, "pool" => 5, "checkout_timeout" => 100 },
    "primary_replica5"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica5.sqlite3", "replica" => true, "pool" => 5, "checkout_timeout" => 100 },
    "primary_replica6"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica6.sqlite3", "replica" => true, "pool" => 5, "checkout_timeout" => 100 },
  }
}

ActiveRecord::Base.configurations = config

class TestRecord < ActiveRecord::Base
  primary_abstract_class

  connects_to database: {
    writing: :primary, 
    reading1: :primary_replica1,
    reading2: :primary_replica2,
    reading3: :primary_replica3,
    reading4: :primary_replica4,
    reading5: :primary_replica5,
    reading6: :primary_replica6,
  }

  load_balancing :rr, [
      {role: :reading1}, 
      {role: :reading2},
      {role: :reading3},
      {role: :reading4},
      {role: :reading5},
      {role: :reading6},
    ],
    redis: Redis.new(host: 'localhost')
  
  load_balancing :rr2, [
      {role: :reading1}, 
      {role: :reading2},
      {role: :reading3},
      {role: :reading4},
      {role: :reading5},
      {role: :reading6},
    ],
    redis: Redis.new(host: 'localhost')

  load_balancing :lc, [
      {role: :reading1}, 
      {role: :reading2},
      {role: :reading3},
      {role: :reading4},
      {role: :reading5},
      {role: :reading6},
    ],
    algorithm: :least_connection,
    redis: Redis.new(host: 'localhost')

  load_balancing :lc_local, [
      {role: :reading1}, 
      {role: :reading2},
      {role: :reading3},
      {role: :reading4},
      {role: :reading5},
      {role: :reading6},
    ],
    algorithm: :least_connection


  load_balancing :wrr, [
      {role: :reading1, weight: 6}, 
      {role: :reading2, weight: 5},
      {role: :reading3, weight: 4},
      {role: :reading4, weight: 3},
      {role: :reading5, weight: 2},
      {role: :reading6, weight: 1},
    ],
    algorithm: :weight_round_robin

  load_balancing :hash, [
      {role: :reading1}, 
      {role: :reading2},
      {role: :reading3},
      {role: :reading4},
      {role: :reading5},
      {role: :reading6},
    ],
    algorithm: :hash

  load_balancing :randomized, [
      {role: :reading1}, 
      {role: :reading2},
      {role: :reading3},
      {role: :reading4},
      {role: :reading5},
      {role: :reading6},
    ],
    algorithm: :randomized

  load_balancing :lrt, [
      {role: :reading1}, 
      {role: :reading2},
      {role: :reading3},
    ],
    algorithm: :least_response_time,
    redis: Redis.new(host: 'localhost')

  load_balancing :lrt_local, [
      {role: :reading1}, 
      {role: :reading2},
      {role: :reading3},
    ],
    algorithm: :least_response_time
end