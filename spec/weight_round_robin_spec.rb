# frozen_string_literal: true
require_relative "./dummy/models/developer"

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
end
