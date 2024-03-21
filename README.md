# MultiDbsLoadBalancer

Allow to setup load balancers sit on top of [rails multi-databases](https://guides.rubyonrails.org/active_record_multiple_databases.html).

## Installation

```ruby
gem "multi_dbs_load_balancer"

$ bundle install
$ rails g multi_dbs_load_balancer:install
```

## Usage

Declaring load balancers
```ruby
# config/initializers/multi_dbs_load_balancer.rb
    load_balancer.db_down_time = 120
    load_balancer.redis_down_time = 120

    load_balancer.init :rr_load_balancer,
        [
            {role: :reading1}, 
            {role: :reading2},
            {role: :reading3},
        ],
        algorithm: :round_robin,
        redis: Redis.new(...)

    load_balancer.init :us_lrt_load_balancer,
        [
            {shard: :us, role: :reading1}, 
            {shard: :us, role: :reading2},
        ],
        algorithm: :least_response_time,
        redis: Redis.new(...)
```

Now you could use them on controllers/services ...
```ruby
# products_controller.rb
def index
    @products = ActiveRecord::Base.connected_through(:rr_load_balancer) { Product.all }
    # alias methods: connected_by, connected_through_load_balancer
end
```

You could also create and use a Middleware to wrap load balancer base on the request, for example:
```ruby
class LoadBalancerMiddleware
    def initialize(app)
        @app = app
    end

    def call(env)
        request = ActionDispatch::Request.new(env)
        if is_something?(request)
            ActiveRecord::Base.connected_through(:rr_load_balancer) do
                @app.call(env)    
            end
        else
            @app.call(env)
        end
    end

    private def is_something?(request)
        # for example: check if reading request
        request.get? || request.head?
    end
end

Rails.application.config.app_middleware.use LoadBalancerMiddleware
```

## Notes

- Support algorithms: `round_robin`, `weight_round_robin`, `least_connection`, `least_response_time`, `hash`, `randomized`

- Distribute

    If you launch multiple servers then you wish your load balancers will share states between servers,
    there're 3 algorithms that will do that if you provide a redis server: 

    + `round_robin` will share the current database

    +  `least_connection` and `least_response_time` will share the sorted list of databases

    Other algorithms are independent on each server, so you don't need to provide a redis server for them.

- Fail-over

    All load balancers here are passive, they don't track database connections or redis connections.
    
    Whenever it could not connect to a database, it mark that database have down for `db_down_time` seconds and ignore it on the next round, 
    and try to connect to the next available database.

    After `db_down_time` seconds, this database will be assumed available again and the load balancer will not ignore it and try to connect again.

    Whenever the redis-server has down (or you dont setup redis), distribute load balancers will process offline on each server until redis come back.



## Development

run test
```ruby
rake setup_db
rake spec
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails_dbs_load_balancer.
