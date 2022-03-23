FROM python:3.11.0a5-alpine as builder

RUN apk --update add \
    build-base \
    libxml2-dev \
    libxslt-dev \
    openssl-dev \
    libffi-dev

COPY requirements.txt .

RUN pip install --upgrade pip
RUN pip install --prefix /install --no-warn-script-location --no-cache-dir -r requirements.txt

FROM python:3.11.0a5-alpine

RUN apk add --update --no-cache tor curl openrc
# libcurl4-openssl-dev

RUN apk -U upgrade

ARG DOCKER_USER=whoogle
ARG DOCKER_USERID=927
ARG config_dir=/config
RUN mkdir -p $config_dir
RUN chmod a+w $config_dir
VOLUME $config_dir

ARG username=''
ARG password=''
ARG proxyuser=''
ARG proxypass=''
ARG proxytype=''
ARG proxyloc=''
ARG whoogle_dotenv=''
ARG use_https=''

ENV CONFIG_VOLUME=$config_dir \
    WHOOGLE_ALT_IG=$instagram_alt \


WORKDIR /whoogle

COPY --from=builder /install /usr/local
COPY misc/tor/torrc /etc/tor/torrc
COPY misc/tor/start-tor.sh misc/tor/start-tor.sh
COPY app/ app/
COPY run .
#COPY whoogle.env .

# Create user/group to run as
RUN adduser -D -g $DOCKER_USERID -u $DOCKER_USERID $DOCKER_USER

# Fix ownership / permissions
RUN chown -R ${DOCKER_USER}:${DOCKER_USER} /whoogle /var/lib/tor

# Allow writing symlinks to build dir
RUN chown $DOCKER_USERID:$DOCKER_USERID app/static/build

USER $DOCKER_USER:$DOCKER_USER

EXPOSE $EXPOSE_PORT

HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:${EXPOSE_PORT}/healthz || exit 1

CMD misc/tor/start-tor.sh & ./run
