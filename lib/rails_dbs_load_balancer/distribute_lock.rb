class DistributeLock
    include RedisLua
    attr_reader :redis

    def initialize(redis)
        @redis = redis
    end

    def synchronize(name, lock_time = 3600)
        return yield if @redis.nil?
        
        lock_name = "#{name}:lock"
        time_lock = eval_lua_script(LOCK_SCRIPT, LOCK_SCRIPT_SHA1, [lock_name], [lock_time])
        return if time_lock.nil?

        begin
            yield
        ensure
            eval_lua_script(UNLOCK_SCRIPT, UNLOCK_SCRIPT_SHA1, [name], [time_lock.to_s])
        end
    rescue
        yield
    end

    private

        LOCK_SCRIPT = <<~LUA
            local now = redis.call("time")[1]
            local expire_time = now + ARGV[1]
            local current_expire_time = redis.call("get", KEYS[1])

            if current_expire_time and tonumber(now) <= tonumber(current_expire_time) then
                return nil
            else
                local result = redis.call("setex", KEYS[1], ARGV[1] + 1, tostring(expire_time))
                return expire_time
            end
        LUA
        LOCK_SCRIPT_SHA1 = Digest::SHA1.hexdigest LOCK_SCRIPT

        UNLOCK_SCRIPT = <<~LUA
            local current_expire_time = redis.call("get", KEYS[1])

            if current_expire_time == ARGV[1] then
                local result = redis.call("del", KEYS[1])
                return result ~= nil
            else
                return false
            end
        LUA
        UNLOCK_SCRIPT_SHA1 = Digest::SHA1.hexdigest UNLOCK_SCRIPT

end
