RailsDbsLoadBalancer.setup do |load_balancer|
    # load_balancer.init :round_robin,
    #     [
    #         {role: :reading1}, 
    #         {role: :reading2},
    #         {role: :reading3},
    #     ],
    #     algorithm: :round_robin,
    #     redis: Redis.new(host: 'localhost')

    # class LoadBalancerMiddleware
    #     def initialize(app)
    #         @app = app
    #     end
    #
    #     def call(env)
    #         request = ActionDispatch::Request.new(env)
    #         if request.get? || request.head?
    #             ActiveRecord::Base.connected_through_load_balancer(:round_robin) do
    #                 @app.call(env)    
    #             end
    #         else
    #             @app.call(env)
    #         end
    #     end
    # end

    # Rails.application.config.app_middleware.use LoadBalancerMiddleware
end
