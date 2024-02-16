# frozen_string_literal: true
require_relative "./dummy/models/developer"

RSpec.describe "weight round robin algorithm" do
    describe "Not dependent on redis" do
        it "distribute base on ip hash" do
            db = nil
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                db = role
            end.and_yield

            ip = "197.168.1.1"
            allow_any_instance_of(LoadBalancer::IpHash).to receive(:hashcode).with(ip).and_return(1)
            Developer.connected_through_load_balancer(:ip_hash, ip: ip) do
                Developer.all
            end
            expect(db).to eq(:reading2)
        end
    end
end
