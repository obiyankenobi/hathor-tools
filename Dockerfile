FROM openresty/openresty:alpine

# lua-resty-http powers the captcha siteverify call. Fetched from the GitHub
# release because opm.openresty.org rejects package downloads (HTTP 403).
ARG LUA_RESTY_HTTP_VERSION=0.17.1
RUN apk add --no-cache curl \
    && curl -fsSL https://github.com/ledgetech/lua-resty-http/archive/refs/tags/v${LUA_RESTY_HTTP_VERSION}.tar.gz \
       | tar xz -C /tmp \
    && mkdir -p /usr/local/openresty/site/lualib/resty \
    && cp /tmp/lua-resty-http-${LUA_RESTY_HTTP_VERSION}/lib/resty/*.lua /usr/local/openresty/site/lualib/resty/ \
    && rm -rf /tmp/lua-resty-http-${LUA_RESTY_HTTP_VERSION}

COPY faucet-nginx.conf /etc/nginx/conf.d/
COPY faucet.lua        /usr/local/openresty/site/lualib/
COPY faucet.html       /usr/share/nginx/html/

EXPOSE 8082
