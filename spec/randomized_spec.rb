# frozen_string_literal: true
require_relative "./dummy/models/developer"

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
end
