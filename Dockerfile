FROM python:2.7-alpine
MAINTAINER Hypothes.is Project and Ilya Kreymer

# Install runtime deps.
RUN apk add --update \
    collectd \
    libffi \
    openssl \
    supervisor \
    squid \
  && rm -rf /var/cache/apk/*

# Create the via user, group, home directory and package directory.
RUN addgroup -S via && adduser -S -G via -h /var/lib/via via
WORKDIR /var/lib/via

ADD requirements.txt .

# Install build deps, build, and then clean up.
RUN apk add --update --virtual build-deps \
    build-base \
    git \
    libffi-dev \
    linux-headers \
    openssl-dev \
  && pip install --no-cache-dir -r requirements.txt \
  && apk del build-deps \
  && rm -rf /var/cache/apk/*

# Copy collectd config
COPY conf/collectd.conf /etc/collectd/collectd.conf
RUN mkdir /etc/collectd/collectd.conf.d \
 && chown via:via /etc/collectd/collectd.conf.d

# Copy squid config
COPY conf/squid.conf /etc/squid/squid.conf
RUN mkdir /var/spool/squid \
 && chown via:via /var/run/squid /var/spool/squid /var/log/squid

# Use local squid by default
ENV HTTP_PROXY http://localhost:3128
ENV HTTPS_PROXY http://localhost:3128

# Install app.
COPY . .

EXPOSE 9080

USER via
CMD ["supervisord", "-c" , "conf/supervisord.conf"]
