# Use nginx as base image
FROM nginx:alpine

# Copy HTML files to nginx html directory
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

