# frozen_string_literal: true
require_relative "./dummy/models/developer"
require_relative "./shared_examples"

RSpec.describe "hash algorithm" do
    describe "Not dependent on redis" do
        it "distribute base on ip hash" do
            db = nil
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                db = role
            end.and_yield

            ip = "197.168.1.1"
            Developer.connected_by(:hash, source: ip) do
                Developer.all
            end
            expect(db).to eq(:reading2)

            url = "/api/books/156"
            Developer.connected_by(:hash, source: url) do
                Developer.all
            end
            expect(db).to eq(:reading6)

            Developer.connected_by(:hash, hash_func: lambda { |str| 2 }, source: url) do
                Developer.all
            end
            expect(db).to eq(:reading3)
        end
    end

    context "one database failed" do
        before do
            LoadBalancer::Hash.class_variable_set(:@@db_down_times, {})
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
            ip = "197.168.1.1"
            Developer.connected_by(:hash, source: ip) do
                Developer.all
            end

            expect(@counter).to eq({reading2: 1})
        end

        it "should ignore the failed db in an interval time" do
            ip = "197.168.1.1"
            Developer.connected_by(:hash, source: ip) do
                Developer.all
            end

            # back to normal
            allow(ActiveRecord::Base).to receive(:connected_to) do |role:, **configs|
                @counter[role] += 1
            end

            Developer.connected_by(:hash, source: ip) do
                Developer.all
            end

            # still ignore the failed db :reading1
            expect(@counter).to eq({reading2: 2})
        end
    end

    it_behaves_like "when all databases have down", lb: :hash, source: "197.168.1.1"
end
