require 'benchmark/ips'
require_relative "./lib/rails_dbs_load_balancer"
require_relative "./spec/dummy/models/developer"

Benchmark.ips do |bm|
    bm.report("ActiveRecord#connected_to") do
        threads = []
        [:reading1, :reading2, :reading3, :reading4, :reading5, :reading6].each do |db|
            10.times do |i|
                threads << Thread.new do
                    ActiveRecord::Base.connected_to(role: db) do
                        result = Developer.all
                    end
                end
            end
        end
        threads.map(&:join)
    end

    bm.report("connect through round robin load balancer") do
        threads = []
        60.times do |i|
            threads << Thread.new do
                Developer.connected_through_load_balancer(:rr) do
                    result = Developer.all
                end
            end
        end
        threads.map(&:join)
    end

    bm.report("connect through least connection load balancer") do
        threads = []
        60.times do |i|
            threads << Thread.new do
                Developer.connected_through_load_balancer(:lc) do
                    result = Developer.all
                end
            end
        end
        threads.map(&:join)
    end

    bm.report("connect through least response time load balancer") do
        threads = []
        60.times do |i|
            threads << Thread.new do
                Developer.connected_through_load_balancer(:lrt) do
                    result = Developer.all
                end
            end
        end
        threads.map(&:join)
    end

    bm.report("connect through weight round robin load balancer") do
        threads = []
        60.times do |i|
            threads << Thread.new do
                Developer.connected_through_load_balancer(:wrr) do
                    result = Developer.all
                end
            end
        end
        threads.map(&:join)
    end

    bm.report("connect through hash load balancer") do
        threads = []
        60.times do |i|
            threads << Thread.new do
                Developer.connected_through_load_balancer(:hash, source: "197.168.1.1") do
                    result = Developer.all
                end
            end
        end
        threads.map(&:join)
    end

    bm.report("connect through randomized load balancer") do
        threads = []
        60.times do |i|
            threads << Thread.new do
                Developer.connected_through_load_balancer(:randomized) do
                    result = Developer.all
                end
            end
        end
        threads.map(&:join)
    end

    bm.compare!
end
