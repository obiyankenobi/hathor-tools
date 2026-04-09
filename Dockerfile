FROM openresty/openresty:alpine

# perl + curl are needed by opm; lua-resty-http powers the captcha siteverify call.
RUN apk add --no-cache perl curl \
    && opm get ledgetech/lua-resty-http

COPY faucet-nginx.conf /etc/nginx/conf.d/
COPY faucet.html       /usr/share/nginx/html/

EXPOSE 8082
