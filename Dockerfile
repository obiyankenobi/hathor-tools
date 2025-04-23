FROM nginx:alpine

# Copy the nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the static files
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80 