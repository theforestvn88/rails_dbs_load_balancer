require_relative "./algo"

module LoadBalancer
    class Randomized < Algo
        def next_db(**options)
            @database_configs[random_index(**options)]
        end

        private

        def random_index(**options)
            rand(0...@database_configs.size)
        end
    end
end
