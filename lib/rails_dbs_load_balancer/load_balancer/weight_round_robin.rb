require_relative "./algo"

module LoadBalancer
    class WeightRoundRobin < Algo
        cattr_reader :mutexes, default: {}
        cattr_reader :cum_weights, default: {}
        cattr_reader :weight_sums, default: ::Hash.new(0)

        def warm_up
            (@@mutexes[weights_key] ||= Mutex.new).synchronize do
                return if @@cum_weights.has_key?(weights_key) or @database_configs.empty?

                @@cum_weights[weights_key] = [@database_configs[0][:weight]]
                (1...@database_configs.size).each do |i|
                    @@weight_sums[weight_sum_key] += @database_configs[i][:weight]
                    @@cum_weights[weights_key][i] = @@cum_weights[weights_key][i-1] + @database_configs[i][:weight]
                end
            end
        end

        def next_db(**options)
            @database_configs[pick_weight]
        end

        private

        def weights_key
            "#{@key}:weights"
        end

        def weight_sum_key
            "#{@key}:weight_sum"
        end

        def random_weight
            rand(@@weight_sums[weight_sum_key]-1)
        end

        def pick_weight
            rw = random_weight
            @@cum_weights[weights_key].find_index do |weight|
                weight > rw
            end
        end
    end
end
