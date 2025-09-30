# Stage 1: build Flutter web app
FROM ghcr.io/cirruslabs/flutter:3.22.2 AS build
WORKDIR /app

# Copy config first for dependency caching
COPY pubspec.yaml analysis_options.yaml ./
RUN flutter pub get

# Copy the rest of the project
COPY . .

# Allows overriding the API base URL during build
ARG API_BASE_URL=https://pottery-api.example.com

RUN flutter build web \
    --release \
    --dart-define=API_BASE_URL=${API_BASE_URL}

# Stage 2: serve via nginx
FROM nginx:1.25-alpine AS runtime

COPY --from=build /app/build/web /usr/share/nginx/html

# Provide default nginx config optimized for single page app routing
COPY deployment/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
