RailsDbsLoadBalancer.setup do |load_balancer|
    # load_balancer.init :round_robin,
    #     [
    #         {role: :reading1}, 
    #         {role: :reading2},
    #         {role: :reading3},
    #     ],
    #     algorithm: :round_robin,
    #     redis: Redis.new(host: 'localhost')
end
