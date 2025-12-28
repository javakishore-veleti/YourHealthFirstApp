# Stage 1: Build the Angular application
FROM node:20-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files first for better layer caching
COPY package*.json ./

# Install dependencies
RUN npm ci --legacy-peer-deps

# Copy the rest of the application source code
COPY . .

# Build the Angular app for production
# Adjust the project name if different in angular.json
RUN npm run build -- --configuration=production

# Stage 2: Serve the application with Nginx
FROM nginx:alpine AS production

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy custom nginx configuration for Cloud Run
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built Angular app from build stage
# Adjust the path based on your angular.json outputPath
# Common patterns: dist/healthcare_plans_ui, dist/healthcare-plans-ui, or dist/browser
COPY --from=build /app/dist/healthcare_plans_ui/browser /usr/share/nginx/html

# Cloud Run requires the container to listen on port 8080
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]