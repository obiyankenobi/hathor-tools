-- =============================================================================
-- Hathor Testnet Faucet - shared drip logic
--
-- Used by every network's /wallet/simple-send-tx location in
-- faucet-nginx.conf. `network` namespaces the per-IP cooldown so a drip on
-- one network doesn't block a drip on another.
-- =============================================================================

local http  = require "resty.http"
local cjson = require "cjson.safe"

local _M = {}

local COOLDOWN   = 21600   -- 6 hours in seconds
local DRIP_VALUE = 100000  -- 1000 HTR (HTR has 2 decimals)

local function deny(status, payload)
    ngx.status = status
    ngx.header["Content-Type"] = "application/json"
    ngx.say(cjson.encode(payload))
    return ngx.exit(ngx.HTTP_OK)
end

local function tracker_key(network, ip)
    return network .. ":" .. ip
end

-- access_by_lua phase: cooldown, captcha, and body rewrite.
function _M.access(network)
    -- -------------------------------------------------------------------
    -- 1. Per-IP cooldown check (cheap, fail fast before captcha).
    -- -------------------------------------------------------------------
    local client_ip = ngx.var.remote_addr
    if client_ip then
        local tracker = ngx.shared.faucet_ip_tracker
        local last_ts = tracker:get(tracker_key(network, client_ip))
        if last_ts then
            local elapsed   = ngx.time() - last_ts
            local remaining = COOLDOWN - elapsed
            if remaining > 0 then
                ngx.header["Retry-After"] = tostring(remaining)
                return deny(429, {
                    success = false,
                    error = "cooldown",
                    retry_after = remaining,
                })
            end
        end
    end

    -- -------------------------------------------------------------------
    -- 2. Captcha token must be present.
    -- -------------------------------------------------------------------
    local token = ngx.req.get_headers()["X-Captcha-Token"]
    if not token or token == "" then
        ngx.log(ngx.WARN, "faucet[", network, "]: missing captcha token from ",
                          client_ip or "?")
        return deny(400, {
            success = false,
            error = "Captcha token required",
        })
    end

    -- -------------------------------------------------------------------
    -- 3. Verify captcha with Google.
    -- -------------------------------------------------------------------
    local secret = ngx.shared.captcha_config:get("secret")
    local httpc  = http.new()
    httpc:set_timeouts(2000, 3000, 5000)  -- connect, send, read (ms)

    local body = ngx.encode_args({
        secret   = secret,
        response = token,
        remoteip = client_ip,
    })

    local res, err = httpc:request_uri(
        "https://www.google.com/recaptcha/api/siteverify",
        {
            method  = "POST",
            body    = body,
            headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded",
            },
            ssl_verify = true,
        }
    )

    if not res then
        ngx.log(ngx.ERR, "faucet: captcha siteverify request failed: ", err)
        return deny(502, {
            success = false,
            error = "captcha verification unreachable",
        })
    end

    if res.status ~= 200 then
        ngx.log(ngx.ERR, "faucet: captcha siteverify HTTP ", res.status,
                         " body=", res.body or "")
        return deny(502, {
            success = false,
            error = "captcha verification failed",
        })
    end

    local response_data = cjson.decode(res.body or "")
    if not response_data then
        ngx.log(ngx.ERR, "faucet: could not decode captcha response: ",
                         res.body or "")
        return deny(502, {
            success = false,
            error = "captcha verification malformed",
        })
    end

    if not response_data.success then
        ngx.log(ngx.WARN, "faucet[", network, "]: captcha rejected for ",
                          client_ip or "?",
                          " errors=", cjson.encode(response_data["error-codes"] or {}))
        return deny(400, {
            success = false,
            error = "Invalid captcha",
        })
    end

    -- -------------------------------------------------------------------
    -- 4. Rewrite the request body to inject the faucet drip amount.
    --    The client only sends the address; we control the value
    --    server-side so it can never be tampered with.
    -- -------------------------------------------------------------------
    ngx.req.read_body()
    local req_body = ngx.req.get_body_data()
    if not req_body then
        return deny(400, {
            success = false,
            error = "Empty request body",
        })
    end

    local data = cjson.decode(req_body)
    if not data or not data.address then
        return deny(400, {
            success = false,
            error = "Invalid request body",
        })
    end

    data.value = DRIP_VALUE
    ngx.req.set_body_data(cjson.encode(data))
end

-- body_filter_by_lua phase: set the per-IP cooldown only if the wallet
-- actually accepted the request *and* returned a successful body. The wallet
-- headless can respond 200 with {"success": false, ...} for application
-- errors (insufficient funds, invalid address, etc.) — those should NOT
-- consume a cooldown slot.
--
-- We buffer the upstream body in ngx.ctx without modifying it (ngx.arg[1]
-- passes through untouched), then on EOF check for the success marker and
-- set the tracker entry.
function _M.body_filter(network)
    if ngx.status ~= 200 then return end
    ngx.ctx.faucet_buf = (ngx.ctx.faucet_buf or "") .. (ngx.arg[1] or "")
    if ngx.arg[2] then  -- eof
        if ngx.ctx.faucet_buf:find('"success":true', 1, true)
           or ngx.ctx.faucet_buf:find('"success": true', 1, true) then
            local ip = ngx.var.remote_addr
            if ip then
                ngx.shared.faucet_ip_tracker:set(tracker_key(network, ip),
                                                 ngx.time(), COOLDOWN)
            end
        end
    end
end

return _M
