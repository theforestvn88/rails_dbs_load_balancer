MultiDbsLoadBalancer.setup do |load_balancer|
    ## The interval time that any have-down(disconnected, error, ...) db will be ignored,
    ## after that, the load balancer will retry to pick this db if the algorithm point to this
    # load_balancer.db_down_time = 120

    ## The interval time that all algorithms will process in local server if the redis disconnected,
    ## after that, they will retry to connect to redis again.
    # load_balancer.redis_down_time = 120

    # load_balancer.init :round_robin,
    #     [
    #         {role: :reading1}, 
    #         {role: :reading2},
    #         {role: :reading3},
    #     ],
    #     algorithm: :round_robin,
    #     redis: Redis.new(host: 'localhost')
    #
end
