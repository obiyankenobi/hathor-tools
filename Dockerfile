FROM openresty/openresty:alpine

# Install perl, curl and required Lua modules
RUN apk add --no-cache perl curl \
    && opm get ledgetech/lua-resty-http

# Copy the nginx configuration
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# Copy the static files
COPY index.html /usr/share/nginx/html/
COPY faucet.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80 