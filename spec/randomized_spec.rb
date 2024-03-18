# frozen_string_literal: true
require_relative "./dummy/models/developer"
require_relative "./shared_examples"

RSpec.describe "randomized algorithm" do
    describe "Not dependent on redis" do
        it "randomized distribute" do
            db = nil
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                db = role
            end.and_yield

            allow_any_instance_of(Object).to receive(:rand).and_return(2)
            Developer.connected_through_load_balancer(:randomized) do
                Developer.all
            end
            expect(db).to eq(:reading3)
        end
    end

    context "one database failed" do
        before do
            @counter = Hash.new(0)
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                if role == :reading1
                    raise ActiveRecord::ConnectionNotEstablished
                else
                    @counter[role] += 1
                end
            end
            LoadBalancer::Randomized.class_variable_set(:@@db_down_times, {})
        end

        it "should try the next db" do
            allow_any_instance_of(Object).to receive(:rand).and_return(0)
            Developer.connected_through_load_balancer(:randomized) do
                Developer.all
            end

            expect(@counter).not_to eq({reading1: 1})
        end

        it "should ignore the failed db in an interval time" do
            allow_any_instance_of(Object).to receive(:rand).and_return(0)
            
            Developer.connected_through_load_balancer(:randomized) do
                Developer.all
            end
            
            # back to normal
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                @counter[role] += 1
            end

            Developer.connected_through_load_balancer(:randomized) do
                Developer.all
            end

            # still ignore the failed db :reading1
            expect(@counter.has_key?(:reading1)).to be(false)
        end
    end

    it_behaves_like "when all databases have down", lb: :randomized
end
