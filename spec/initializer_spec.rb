# frozen_string_literal: true

RSpec.describe "initializer" do
    it "init load balancer" do
        MultiDbsLoadBalancer.setup do |load_balancer|
            load_balancer.init :init_round_robin,
                [
                    {role: :reading1}, 
                    {role: :reading2},
                    {role: :reading3},
                ],
                algorithm: :round_robin,
                redis: Redis.new(host: 'localhost')
        end

        expect(LoadBalancer.lb[:init_round_robin]).not_to be_nil
    end
end
