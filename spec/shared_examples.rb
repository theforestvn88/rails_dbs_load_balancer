# frozen_string_literal: true


RSpec.shared_examples "when all databases have down" do |lb:, **options|
    before do
        allow(ActiveRecord::Base).to receive(:connected_to).and_raise(ActiveRecord::ConnectionNotEstablished)
    end

    it "should raise error" do
        expect {
            Developer.connected_through(lb, **options) do
                Developer.all
            end
        }.to raise_error(LoadBalancer::AllDatabasesHaveDown)
    end
end
