# frozen_string_literal: true
require_relative "./dummy/models/developer"

RSpec.describe "least-connection algorithm" do
    it "warm-up setup a connections redis priority queue" do
        redis = Redis.new(host: "localhost")
        redis.del("lc:lock")
        redis.del("lc:pq")

        (0..10).map do |i|
            Thread.new do
                config = LoadBalancer.lb[:lc]
                lb = config[:clazz].new(config[:db_configs], redis: config[:redis], key: config[:key])
                lb.warm_up
            end
        end.map(&:join)

        
        expect(redis.zrange("lc:pq", 0, -1)).to eq((0..5).map(&:to_s))
    end

    it "should distribute to the least connection database" do
        redis = Redis.new(host: "localhost")
        redis.del("lc:pq")
        redis.zincrby("lc:pq", 3, 0)
        redis.zincrby("lc:pq", 2, 1)
        redis.zincrby("lc:pq", 1, 2)
        redis.zincrby("lc:pq", 2, 3)
        redis.zincrby("lc:pq", 3, 4)
        redis.zincrby("lc:pq", 3, 5)

        least_role = nil
        allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
            least_role = role
        end#.and_yield

        Developer.connected_through_load_balancer(:lc) do
            Developer.all
        end

        expect(least_role).to eq(:reading3)
    end

    # context "redis failed" do
    # end
end
