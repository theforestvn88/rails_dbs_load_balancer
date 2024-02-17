# frozen_string_literal: true
require_relative "./dummy/models/developer"

RSpec.describe "hash algorithm" do
    describe "Not dependent on redis" do
        it "distribute base on ip hash" do
            db = nil
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                db = role
            end.and_yield

            ip = "197.168.1.1"
            Developer.connected_through_load_balancer(:hash, source: ip) do
                Developer.all
            end
            expect(db).to eq(:reading2)

            url = "thisisaaaaaalongongongogngonggongognogngongogngongongongogngongongognognogngongongogngoogosngksdfkshdfshdfkshdfkjshdfjkhsdfkjdhsfkjdfshkj/api/books/156"
            Developer.connected_through_load_balancer(:hash, source: url) do
                Developer.all
            end
            expect(db).to eq(:reading3)
        end
    end
end
