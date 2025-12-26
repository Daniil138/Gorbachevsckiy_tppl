local socket = require("socket")

local secret_key = "isu_pt"
local host = "95.163.237.76"
local port1, port2 = 5123, 5124
local output_file = "servers_data.log"

local retry_delay = 2  
local success_delay = 1 

local function unpack_uint64(str, pos)
    local val = 0
    for i = 0, 7 do
        val = val * 256 + string.byte(str, pos + i)
    end
    return val
end

local function unpack_int32(str, pos)
    local b1, b2, b3, b4 = string.byte(str, pos, pos + 3)
    local val = (b1 * 0x1000000) + (b2 * 0x10000) + (b3 * 0x100) + b4
    if val >= 0x80000000 then
        val = val - 0x100000000
    end
    return val
end

local function unpack_float(str, pos)
    local b1, b2, b3, b4 = string.byte(str, pos, pos + 3)
    if not b4 then return 0.0 end
    local uint = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
    if uint == 0 then return 0.0 end

    local sign = (uint >= 0x80000000) and -1 or 1

    local exp = math.floor(uint / 8388608) % 256  

    local mantissa = uint % 8388608 

    if exp == 0 then
        return sign * mantissa / 8388608 * (2^-126) 
    elseif exp == 255 then
        if mantissa == 0 then
            return sign * math.huge
        else
            return 0/0  -- NaN
        end
    else
        return sign * (1 + mantissa / 8388608) * (2^(exp - 127))
    end
end

local function unpack_int16(str, pos)
    local lo, hi = string.byte(str, pos), string.byte(str, pos + 1)
    local val = lo + hi * 256
    if val >= 0x8000 then
        val = val - 0x10000
    end
    return val
end


local function log_to_file(line)
    local f = io.open(output_file, "a")
    if f then
        f:write(os.date("%Y-%m-%d %H:%M:%S") .. " | " .. line .. "\n")
        f:close()
    end
    print(os.date("%Y-%m-%d %H:%M:%S") .. " | " .. line)
end


local function fetch_5123()
    local sock = socket.tcp()
    sock:settimeout(1)

    local ok, err = sock:connect(host, port1)
    if not ok then
        sock:close()
        return nil, "connect failed: " .. tostring(err)
    end

    local sent, err = sock:send(secret_key)
    if not sent then
        sock:close()
        return nil, "send secret failed: " .. tostring(err)
    end

    sock:receive(1024)

    local sent, err = sock:send("get")
    if not sent then
        sock:close()
        return nil, "send 'get' failed: " .. tostring(err)
    end

    local data, err = sock:receive(15)
    if not data or #data ~= 15 then
        sock:close()
        return nil, "received " .. (data and #data or 0) .. " bytes, expected 15"
    end

    local sum = 0
    for i = 1, 14 do sum = (sum + string.byte(data, i)) % 256 end
    local cs = string.byte(data, 15)
    if sum ~= cs then
        sock:close()
        return nil, "checksum mismatch"
    end

    

    local ts = unpack_uint64(data, 1)
    local temperature = unpack_float(data, 9)
    local pressure = unpack_int16(data, 13)

    sock:close()
    return {
        datetime = os.date("%Y-%m-%d %H:%M:%S", math.floor(ts / 1e6)),
        temperature = temperature,
        pressure = pressure
    }
end



local function fetch_5124()
    local sock = socket.tcp()
    sock:settimeout(1)

    local ok, err = sock:connect(host, port2)
    if not ok then
        sock:close()
        return nil, "connect failed: " .. tostring(err)
    end

    local sent, err = sock:send(secret_key)
    if not sent then
        sock:close()
        return nil, "send secret failed: " .. tostring(err)
    end

    sock:receive(1024)
    sock:send("get")

    local data, err = sock:receive(21)
    if not data or #data ~= 21 then
        sock:close()
        return nil, "received " .. (data and #data or 0) .. " bytes, expected 21"
    end

    local sum = 0
    for i = 1, 20 do sum = (sum + string.byte(data, i)) % 256 end
    local cs = string.byte(data, 21)
    if sum ~= cs then
        sock:close()
        return nil, "checksum mismatch"
    end

    local ts = unpack_uint64(data, 1)
    local X = unpack_int32(data, 9)
    local Y = unpack_int32(data, 13)
    local Z = unpack_int32(data, 17)
    sock:close()
    return { timestamp_us = ts, X = X, Y = Y, Z = Z, datetime = os.date("%Y-%m-%d %H:%M:%S", math.floor(ts / 1e6)) }
end

local function main()
    log_to_file("=== Dual-server logger started ===")
    while true do
        local success = false

        local d1, err1 = fetch_5123()
        if d1 then
            local line = string.format("[5123] datetime=%s, temperature=%.3f, pressure=%d", d1.datetime, d1.temperature, d1.pressure)
            log_to_file(line)
            success = true
        else
            log_to_file("[5123] ERROR: " .. tostring(err1))
        end

        local d2, err2 = fetch_5124()
        if d2 then
            local line = string.format("[5124] datetime=%s, X=%d, Y=%d, Z=%d",
                d2.datetime, d2.X, d2.Y, d2.Z)
            log_to_file(line)
            success = true
        else
            log_to_file("[5124] ERROR: " .. tostring(err2))
        end

        local delay = success and success_delay or retry_delay
        socket.sleep(delay)
    end
end

local ok, err = pcall(main)
if not ok then
    log_to_file("CRITICAL ERROR: " .. tostring(err))
end