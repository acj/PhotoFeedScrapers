FROM ruby:3.3-slim

ENV LANG=C.UTF-8 \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    DB_PATH=/data/photofeeds.sqlite3 \
    OUTPUT_PATH=/data/feed.xml \
    CRON_SCHEDULE="0 */6 * * *"

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libsqlite3-dev \
        ca-certificates \
        tzdata \
        curl \
    && rm -rf /var/lib/apt/lists/*

ARG SUPERCRONIC_VERSION=v0.2.30
ARG SUPERCRONIC_SHA1SUM=9aeb41e00cc7b71d30d33c57a2333f2c2581a201
RUN curl -fsSLo /usr/local/bin/supercronic \
      "https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-linux-amd64" \
    && echo "${SUPERCRONIC_SHA1SUM}  /usr/local/bin/supercronic" | sha1sum -c - \
    && chmod +x /usr/local/bin/supercronic

WORKDIR /app
COPY Gemfile Gemfile.lock* ./
RUN gem install bundler && bundle install

COPY lib ./lib
COPY bin ./bin
COPY public ./public
RUN chmod +x ./bin/scrape

RUN mkdir -p /data
VOLUME ["/data"]

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
