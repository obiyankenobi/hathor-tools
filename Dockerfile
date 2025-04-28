FROM openresty/openresty:alpine

# Install perl, curl and required Lua modules
RUN apk add --no-cache perl curl \
    && opm get ledgetech/lua-resty-http

# Create directory for sites
RUN mkdir -p /etc/nginx/conf.d

# Copy the nginx configurations
#COPY blueprint-nginx.conf /etc/nginx/sites-enabled/
#COPY faucet-nginx.conf /etc/nginx/sites-enabled/
COPY blueprint-nginx.conf /etc/nginx/conf.d/
COPY faucet-nginx.conf /etc/nginx/conf.d/
#etc/nginx/conf.d/*.conf;

# Create a base nginx.conf that includes the site configurations
#RUN echo 'events { worker_connections 1024; } \n\
#http { \n\
#    include mime.types; \n\
#    include /etc/nginx/sites-enabled/*; \n\
#}' > /usr/local/openresty/nginx/conf/nginx.conf

# Copy the static files
COPY blueprint.html /usr/share/nginx/html/
COPY faucet.html /usr/share/nginx/html/

# Expose ports
EXPOSE 8081 8082 