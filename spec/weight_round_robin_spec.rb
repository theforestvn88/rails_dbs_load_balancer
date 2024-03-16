# frozen_string_literal: true
require_relative "./dummy/models/developer"
require_relative "./shared_examples"

RSpec.describe "weight round robin algorithm" do
    describe "Not dependent on redis" do
        it "should distribute to all databases base on weight" do
            db = nil
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                db = role
            end.and_yield

            allow_any_instance_of(Object).to receive(:rand).and_return(5)
            Developer.connected_through_load_balancer(:wrr) do
                Developer.all
            end
            expect(db).to eq(:reading1)

            allow_any_instance_of(Object).to receive(:rand).and_return(6)
            Developer.connected_through_load_balancer(:wrr) do
                Developer.all
            end
            expect(db).to eq(:reading2)

            allow_any_instance_of(Object).to receive(:rand).and_return(12)
            Developer.connected_through_load_balancer(:wrr) do
                Developer.all
            end
            expect(db).to eq(:reading3)

            allow_any_instance_of(Object).to receive(:rand).and_return(20)
            Developer.connected_through_load_balancer(:wrr) do
                Developer.all
            end
            expect(db).to eq(:reading6)
        end
    end

    context "one database failed" do
        before do
            LoadBalancer::WeightRoundRobin.class_variable_set(:@@down_times, {})

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
            allow_any_instance_of(Object).to receive(:rand).and_return(5)
            Developer.connected_through_load_balancer(:wrr) do
                Developer.all
            end

            expect(@counter).to eq({reading2: 1})
        end

        it "should ignore the failed db in an interval time" do
            allow_any_instance_of(Object).to receive(:rand).and_return(5)

            Developer.connected_through_load_balancer(:wrr) do
                Developer.all
            end

            # back to normal
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                @counter[role] += 1
            end

            Developer.connected_through_load_balancer(:wrr) do
                Developer.all
            end

            # still ignore the failed db :reading1
            expect(@counter).to eq({reading2: 2})
        end
    end

    it_behaves_like "when all databases have down", lb: :wrr
end
