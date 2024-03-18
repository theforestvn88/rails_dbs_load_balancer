# frozen_string_literal: true
require_relative "./dummy/models/developer"
require_relative "./shared_examples"

RSpec.describe "least-response-time algorithm" do
    describe "warm-up setup a connections priority queue" do
        context "with redis" do
            it "create redis priority queue" do
                redis = Redis.new(host: "localhost")
                redis.del("lrt:lock")
                redis.del("lrt:lrt:pq")

                (0..10).map do |i|
                    Thread.new do
                        config = LoadBalancer.lb[:lrt]
                        lb = config[:clazz].new(config[:db_configs], redis: config[:redis], key: config[:key])
                        lb.warm_up
                    end
                end.map(&:join)

        
                expect(redis.zrange("lrt:lrt:pq", 0, -1)).to eq((0..2).map(&:to_s))
            end
        end

        context "without redis" do
            it "create local priority queue" do
                (0..10).map do |i|
                    Thread.new do
                        config = LoadBalancer.lb[:lrt_local]
                        lb = config[:clazz].new(config[:db_configs], redis: config[:redis], key: config[:key])
                        lb.warm_up
                    end
                end.map(&:join)

                queue = LoadBalancer::LeastResponseTime.response_times["lrt_local:lrt:pq"]
                indexes = queue.instance_variable_get(:@items)
                expect(indexes.sort).to eq((0..2).map { |i| [0, i] })
            end
        end
    end

    describe "should select the least response-time db connection" do
        context "with redis" do
            it "base on redis priority queue" do
                least_response_time_dbs = []
                allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                    least_response_time_dbs << role
                end.and_yield

                Thread.new do
                    Developer.connected_through_load_balancer(:lrt) do
                        Developer.all
                        sleep 0.2
                    end
                end.join

                Thread.new do
                    Developer.connected_through_load_balancer(:lrt) do
                        Developer.all
                        sleep 0.1
                    end
                end.join

                Thread.new do
                    Developer.connected_through_load_balancer(:lrt) do
                        Developer.all
                        sleep 0.3
                    end
                end.join

                Developer.connected_through_load_balancer(:lrt) do
                    Developer.all
                end

                expect(least_response_time_dbs.last).to eq(:reading2)
            end
        end

        context "without redis" do
            it "base on local priority queue" do
                least_response_time_dbs = []
                allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                    least_response_time_dbs << role
                end.and_yield

                Thread.new do
                    Developer.connected_through_load_balancer(:lrt_local) do
                        Developer.all
                        sleep 0.5
                    end
                end.join

                Thread.new do
                    Developer.connected_through_load_balancer(:lrt_local) do
                        Developer.all
                        sleep 0.1
                    end
                end.join

                Thread.new do
                    Developer.connected_through_load_balancer(:lrt_local) do
                        Developer.all
                        sleep 0.5
                    end
                end.join

                Developer.connected_through_load_balancer(:lrt_local) do
                    Developer.all
                end

                expect(least_response_time_dbs.last).to eq(:reading2)
            end
        end
    end

    context "one database failed" do
        before do
            LoadBalancer::LeastResponseTime.class_variable_set(:@@db_down_times, {})

            @redis = Redis.new(host: "localhost")
            @redis.zincrby("lrt:lrt:pq", 1, 0)
            @redis.zincrby("lrt:lrt:pq", 3, 1)
            @redis.zincrby("lrt:lrt:pq", 2, 2)

            @least_response_role = nil
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                if role == :reading1
                    raise ActiveRecord::ConnectionNotEstablished
                else
                    @least_response_role = role
                end
            end.and_yield
        end

        it "should try the next least connect db" do
            Developer.connected_through_load_balancer(:lrt) do
                Developer.all
            end
    
            expect(@least_response_role).to eq(:reading3)
        end

        it "should ignore the failed db in an interval time" do
            Developer.connected_through_load_balancer(:lrt) do
                Developer.all
            end

            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                @least_response_role = role
            end.and_yield

            Developer.connected_through_load_balancer(:lrt) do
                Developer.all
            end

            expect(@least_response_role).to eq(:reading3)
        end
    end

    it_behaves_like "when all databases have down", lb: :lrt
end
