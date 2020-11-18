FROM ubuntu:groovy as base
RUN apt-get update

FROM base as dependencies
ARG JRE='openjdk-14-jre-headless'

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install $JRE gdal-bin tesseract-ocr \
    tesseract-ocr-all

RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y xfonts-utils fonts-freefont-ttf fonts-liberation ttf-mscorefonts-installer wget cabextract

FROM dependencies as fetch_tika
ARG CHECK_SIG=true

ENV NEAREST_TIKA_SERVER_URL="https://www.apache.org/dyn/closer.cgi/tika/tika-server-1.24.1.jar?filename=tika/tika-server-1.24.1.jar&action=download" \
    ARCHIVE_TIKA_SERVER_URL="https://archive.apache.org/dist/tika/tika-server-1.24.1.jar" \
    DEFAULT_TIKA_SERVER_ASC_URL="https://downloads.apache.org/tika/tika-server-1.24.1.jar.asc" \
    ARCHIVE_TIKA_SERVER_ASC_URL="https://archive.apache.org/dist/tika/tika-server-1.24.1.jar.asc" \
    TIKA_VERSION=$TIKA_VERSION

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install gnupg2 wget \
    && wget -t 10 --max-redirect 1 --retry-connrefused -qO- https://downloads.apache.org/tika/KEYS | gpg --import \
    && wget -t 10 --max-redirect 1 --retry-connrefused $NEAREST_TIKA_SERVER_URL -O /tika-server-1.24.1.jar || rm /tika-server-1.24.1.jar \
    && sh -c "[ -f /tika-server-1.24.1.jar ]" || wget $ARCHIVE_TIKA_SERVER_URL -O /tika-server-1.24.1.jar || rm /tika-server-1.24.1.jar \
    && sh -c "[ -f /tika-server-1.24.1.jar ]" || exit 1 \
    && wget -t 10 --max-redirect 1 --retry-connrefused $DEFAULT_TIKA_SERVER_ASC_URL -O /tika-server-1.24.1.jar.asc  || rm /tika-server-1.24.1.jar.asc \
    && sh -c "[ -f /tika-server-1.24.1.jar.asc ]" || wget $ARCHIVE_TIKA_SERVER_ASC_URL -O /tika-server-1.24.1.jar.asc || rm /tika-server-1.24.1.jar.asc \
    && sh -c "[ -f /tika-server-1.24.1.jar.asc ]" || exit 1;

RUN if [ "$CHECK_SIG" = "true" ] ; then gpg --verify /tika-server-1.24.1.jar.asc /tika-server-1.24.1.jar; fi

FROM dependencies as runtime
RUN apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ARG TIKA_VERSION
ENV TIKA_VERSION=$TIKA_VERSION
COPY --from=fetch_tika /tika-server-1.24.1.jar /tika-server-1.24.1.jar

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get -y install curl \
	
RUN apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chown=root:root assets/entrypoint.sh assets/tika-config.template.xml /
RUN chmod +x /entrypoint.sh
	
HEALTHCHECK CMD curl -f http://0.0.0.0:9998/tika?hc=1 || exit 1
ENTRYPOINT /entrypoint.sh
