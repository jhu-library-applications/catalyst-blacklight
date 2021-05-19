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
  curl

RUN apk add --no-cache 'chromium-chromedriver>90.0' --repository http://dl-cdn.alpinelinux.org/alpine/edge/community


RUN mkdir -p /catalyst
WORKDIR /catalyst

EXPOSE 3000

CMD bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0'"
