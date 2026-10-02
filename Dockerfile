# Stage 1: Build Flutter Web using official Flutter SDK on Ubuntu
FROM ubuntu:22.04 AS build

# Install build tools & dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Download official Flutter SDK directly from Google Storage
RUN curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz \
    && tar xf flutter_linux_3.24.3-stable.tar.xz -C /opt \
    && rm flutter_linux_3.24.3-stable.tar.xz

ENV PATH="/opt/flutter/bin:${PATH}"

RUN git config --global --add safe.directory /opt/flutter
RUN flutter config --enable-web

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=https://autorecue-backend.onrender.com

# Stage 2: Serve using lightweight Nginx container
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
