# frozen_string_literal: true
require_relative "./dummy/models/developer"
require_relative "./shared_examples"

RSpec.describe "round robin algorithm" do
    before do
        @redis = Redis.new(host: "localhost")
        @redis.del("rr:rr:current")
        @redis.del("rr:lock")
        LoadBalancer::RoundRobin.class_variable_set(:@@db_down_times, {})
    end

    it "should fair distribute to all databases" do
        counter = Hash.new(0)
        allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
            counter[role] += 1
        end

        threads = []
        36.times do |i|
            threads << Thread.new do
                Developer.connected_through_load_balancer(:rr) do
                    Developer.all
                end
            end
        end
        threads.map(&:join)
        
        expect(counter).to eq({
            reading1: 6,
            reading2: 6,
            reading3: 6,
            reading4: 6,
            reading5: 6,
            reading6: 6,
        })
    end

    context "redis have down" do
        before do
            allow_any_instance_of(Redis).to receive(:evalsha).and_raise(Redis::CannotConnectError)
            Developer.connected_through_load_balancer(:rr) do
                Developer.all
            end
        end

        it "still fair distribute all db connects on each server base on local server counter" do
            counter = Hash.new(0)
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                counter[role] += 1
            end

            threads = []
            36.times do |i|
                threads << Thread.new do
                    Developer.connected_through_load_balancer(:rr) do
                        Developer.all
                    end
                end
            end
            threads.map(&:join)
            
            expect(counter).to eq({
                reading1: 6,
                reading2: 6,
                reading3: 6,
                reading4: 6,
                reading5: 6,
                reading6: 6,
            })
        end
    end

    context "one database down" do
        before do
            @redis.set("rr2:rr:current", 5)
            @counter = Hash.new(0)
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                if role == :reading1
                    raise ActiveRecord::ConnectionNotEstablished
                else
                    @counter[role] += 1
                end
            end
        end

        it "should try the next db" do
            Developer.connected_through_load_balancer(:rr2) do
                Developer.all
            end

            expect(@counter).to eq({reading2: 1})
        end

        it "should ignore the failed db in an interval time" do
            Developer.connected_through_load_balancer(:rr2) do
                Developer.all
            end

            # back to normal
            @redis.set("rr2:rr:current", 0)
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                @counter[role] += 1
            end

            6.times do
                Developer.connected_through_load_balancer(:rr2) do
                    Developer.all
                end
            end

            # still ignore the failed db :reading1
            expect(@counter).not_to have_key(:reading1)
        end
    end

    it_behaves_like "when all databases have down", lb: :rr
end
