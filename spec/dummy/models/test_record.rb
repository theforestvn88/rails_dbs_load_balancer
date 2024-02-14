require "active_record"
require "redis"

ENV["RAILS_ENV"] = "test"

config = {
  "test" => {
    "primary"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary.sqlite3" },
    "primary_replica1"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica1.sqlite3", "replica" => true },
    "primary_replica2"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica2.sqlite3", "replica" => true },
    "primary_replica3"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica3.sqlite3", "replica" => true },
    "primary_replica4"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica4.sqlite3", "replica" => true },
    "primary_replica5"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica5.sqlite3", "replica" => true },
    "primary_replica6"  => { "adapter" => "sqlite3", "database" => "spec/dummy/db/primary_replica6.sqlite3", "replica" => true },
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

  include LoadBalancer

  load_balancing :test, [
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
end