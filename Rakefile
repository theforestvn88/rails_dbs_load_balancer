# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

task :setup_db do
    p "setup db ..."
    `sqlite3 spec/dummy/db/primary.sqlite3 'CREATE TABLE IF NOT EXISTS developers (name VARCHAR (255))'`
    `sqlite3 spec/dummy/db/primary_replica1.sqlite3 'CREATE TABLE IF NOT EXISTS developers (name VARCHAR (255))'`
    `sqlite3 spec/dummy/db/primary_replica2.sqlite3 'CREATE TABLE IF NOT EXISTS developers (name VARCHAR (255))'`
    `sqlite3 spec/dummy/db/primary_replica3.sqlite3 'CREATE TABLE IF NOT EXISTS developers (name VARCHAR (255))'`
    `sqlite3 spec/dummy/db/primary_replica4.sqlite3 'CREATE TABLE IF NOT EXISTS developers (name VARCHAR (255))'`
    `sqlite3 spec/dummy/db/primary_replica5.sqlite3 'CREATE TABLE IF NOT EXISTS developers (name VARCHAR (255))'`
    `sqlite3 spec/dummy/db/primary_replica6.sqlite3 'CREATE TABLE IF NOT EXISTS developers (name VARCHAR (255))'`
end

RSpec::Core::RakeTask.new(:spec)

task default: [:setup_db, :spec]
