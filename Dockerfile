FROM openresty/openresty:alpine

# Copy the nginx configuration
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# Copy the static files
COPY index.html /usr/share/nginx/html/
COPY faucet.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80 