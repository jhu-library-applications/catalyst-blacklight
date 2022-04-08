FROM ruby:2.6-alpine as builder

RUN apk update && apk add --no-cache \
  bash \
  build-base \
  git \
  libxml2-dev \
  libxslt-dev \
  nodejs \
  mariadb \
  mariadb-dev \
  tzdata \
  shared-mime-info \
  yarn \
  curl \
  openssh \
  openssh-client-common

# Installs latest Chromium package.
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/main" >> /etc/apk/repositories \
  && apk upgrade -U -a \
  && apk add \
  libstdc++ \
  chromium \
  chromium-chromedriver \
  harfbuzz \
  nss \
  freetype \
  ttf-freefont \
  font-noto-emoji \
  wqy-zenhei \
  && rm -rf /var/cache/* \
  && mkdir /var/cache/apk

ENV CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/

RUN mkdir -p /catalyst
WORKDIR /catalyst

EXPOSE 3000

CMD bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0'"
