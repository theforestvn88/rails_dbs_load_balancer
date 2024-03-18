module Healthcheck
    cattr_reader :db_down_times, :redis_down_times

    def mark_redis_down
        set_redis_down_time(Time.now.to_i + 300) # TODO: remove hardcode
    end

    def redis_available?
        @redis.present? && redis_down_time < Time.now.to_i
    end

    def mark_db_down(db_index)
        db_down_times[db_index] = Time.now.to_i + 300 # TODO: remove hardcode
    end

    def db_available?(db_index)
        db_down_times[db_index] < Time.now.to_i
    end

    private def db_down_times
        @@db_down_times ||= {}
        @@db_down_times["#{@key}:dt"] ||= Hash.new(0)
    end

    private def redis_down_times
        @@redis_down_times ||= Hash.new(0)
    end

    private def redis_down_time
        redis_down_times["#{@key}:dt"]
    end

    private def set_redis_down_time(t)
        redis_down_times["#{@key}:dt"] = t
    end
end
