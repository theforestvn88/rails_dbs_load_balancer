# frozen_string_literal: true
require_relative "./dummy/models/developer"

RSpec.describe "least-connection algorithm" do
    it "warm-up setup a connections redis priority queue" do
        redis = Redis.new(host: "localhost")
        redis.del("lc:lock")
        redis.del("lc:lc:pq")

        (0..10).map do |i|
            Thread.new do
                config = LoadBalancer.lb[:lc]
                lb = config[:clazz].new(config[:db_configs], redis: config[:redis], key: config[:key])
                lb.warm_up
            end
        end.map(&:join)

        
        expect(redis.zrange("lc:lc:pq", 0, -1)).to eq((0..5).map(&:to_s))
    end

    it "should distribute to the least connection database" do
        redis = Redis.new(host: "localhost")
        redis.del("lc:lc:pq")
        redis.zincrby("lc:lc:pq", 3, 0)
        redis.zincrby("lc:lc:pq", 2, 1)
        redis.zincrby("lc:lc:pq", 1, 2)
        redis.zincrby("lc:lc:pq", 2, 3)
        redis.zincrby("lc:lc:pq", 3, 4)
        redis.zincrby("lc:lc:pq", 3, 5)

        least_role = nil
        allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
            least_role = role
        end#.and_yield

        Developer.connected_through_load_balancer(:lc) do
            Developer.all
        end

        expect(least_role).to eq(:reading3)
    end

    context "redis nil or redis failed" do
        it "should calculate least connection on each server" do
            pq = LoadBalancer::LeastConnection.leasts["lc_local:lc:pq"] 
            pq.pop until pq.empty?
            pq.push([6, 0])
            pq.push([6, 1])
            pq.push([3, 2])
            pq.push([4, 3])
            pq.push([6, 4])
            pq.push([6, 5])

            least_roles = {}
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                least_roles[Thread.current[:name]] = role
            end.and_yield

            threads = []
            threads << Thread.new do
                Thread.current[:name] = :thread1
                Developer.connected_through_load_balancer(:lc_local) do
                    Developer.all
                    sleep 0.5
                end
            end

            threads << Thread.new do
                Thread.current[:name] = :thread2
                Developer.connected_through_load_balancer(:lc_local) do
                    Developer.all
                    sleep 0.5
                end
            end

            threads << Thread.new do
                sleep 0.1
                Thread.current[:name] = :thread3
                Developer.connected_through_load_balancer(:lc_local) do
                    Developer.all
                    sleep 1.0
                end
            end

            threads << Thread.new do
                sleep 0.7 # wait for :reading3
                Thread.current[:name] = :thread4
                Developer.connected_through_load_balancer(:lc_local) do
                    Developer.all
                end
            end

            threads.each(&:join)

            expect(least_roles).to eq({
                :thread1 => :reading3,
                :thread2 => :reading3,
                :thread3 => :reading4,
                :thread4 => :reading3,
            })
        end
    end
end
