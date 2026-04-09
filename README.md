# Hathor Testnet Faucet

Static web faucet for the Hathor testnet. An OpenResty container serves
`faucet.html`, verifies a Google reCAPTCHA in Lua, enforces per-IP drain
protection, and proxies validated drips to a wallet headless service.

## Prerequisites

- Docker
- Hathor wallet headless reachable from the container at `172.17.0.1:8000`
  (the default Docker bridge gateway)

## Configuration

Before building, edit `faucet-nginx.conf` and replace the placeholder
`YOUR_RECAPTCHA_SECRET_KEY` with the real reCAPTCHA v2 secret key. The
public site key lives in `faucet.html` and is safe to commit.

## Build & run

```bash
docker build -t hathor-faucet .
docker run --rm -p 8082:8082 hathor-faucet
```

The UI is then available at `http://localhost:8082`.

In production, an outer nginx (see `main-nginx.conf`) terminates the
`faucet.testnet.hathor.network` vhost on :80 and reverse-proxies to the
container on :8082.

## Anti-abuse layers

The faucet stacks three independent protections:

1. **Google reCAPTCHA v2** — verified server-side in `access_by_lua_block`
   before any request reaches the wallet.
2. **Burst rate limit** — `limit_req_zone` at 6 req/min per client IP with
   a burst of 1, returning HTTP 429.
3. **Per-IP cooldown** — a `lua_shared_dict` records the timestamp of every
   successful drip and rejects further requests from the same IP for 6
   hours. The cooldown is set in `header_filter_by_lua_block` only when
   the wallet returns 200, so transient wallet errors don't lock users
   out. Cleared on container restart (acceptable for a testnet faucet).

## Real-IP requirement (important)

When a reverse proxy sits in front of the container, the inner nginx must
trust `X-Forwarded-For` or both the rate limit and the IP cooldown collapse
into a single global counter (every request appears to come from the proxy).

`faucet-nginx.conf` already trusts `127.0.0.1` and `172.17.0.0/16`. If you
deploy behind a different proxy (CDN, load balancer, k8s ingress), add its
IP range to `set_real_ip_from`.

## Files

| File | Purpose |
|---|---|
| `faucet.html` | Single-page UI |
| `faucet-nginx.conf` | OpenResty config: rate limit, captcha, cooldown, proxy |
| `Dockerfile` | OpenResty Alpine image with `lua-resty-http` |
| `main-nginx.conf` | Outer reverse proxy vhost (production only) |
