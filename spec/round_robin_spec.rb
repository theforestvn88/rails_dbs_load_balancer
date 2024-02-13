# frozen_string_literal: true
require_relative "./dummy/models/developer"

RSpec.describe "round robin algorithm" do
    it "should fair distribute to all reading databases" do
        counter = Hash.new(0)
        allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
            counter[role] += 1
        end

        threads = []
        36.times do |i|
            threads << Thread.new do
                Developer.connected_through_load_balancer(:test) do
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

    context "redis failed" do
        it "still fair distribute all db connects on each server base on local server counter" do
            allow_any_instance_of(Redis).to receive(:evalsha).and_raise(Redis::CannotConnectError)

            counter = Hash.new(0)
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                counter[role] += 1
            end

            threads = []
            36.times do |i|
                threads << Thread.new do
                    Developer.connected_through_load_balancer(:test) do
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
end
