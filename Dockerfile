FROM debian AS builder

LABEL project="thnx"

ENV PROJECT_NAME 'thnx'

ENV PG_VERSION '14'
ENV PG_CLUSTER 'main'

ENV TZ 'Europe/Moscow'

ENV LANG 'ru_RU.UTF-8'
ENV LC_ALL 'ru_RU.UTF-8'

RUN set -eux; \
    echo $TZ > /etc/timezone;  \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen; \
    echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen; \
    apt-get update && apt-get install -y tzdata locales; \
    rm /etc/localtime;  \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime;  \
    dpkg-reconfigure -f noninteractive tzdata; \
    dpkg-reconfigure -f noninteractive locales; \
    update-locale; \
    apt-get clean; \
    apt-get update -y;

RUN set -eux; \
    apt-get install apt-utils bash build-essential cmake cmake-data g++ gcc libcurl4-openssl-dev libssl-dev make pkg-config sudo wget git htop mc lsb-release -y; \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'; \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -; \
    apt-get update -y; \
    apt-get install postgresql libpq-dev postgresql-server-dev-all -y;

RUN set -eux; \
    pg_dropcluster $PG_VERSION $PG_CLUSTER;

WORKDIR /opt/$PROJECT_NAME

COPY . .

RUN set -eux; \
    cp docker/default.conf conf/default.conf; \
    cmake -DCMAKE_BUILD_TYPE=Release . -B cmake-build-release; \
    cd cmake-build-release; \
    make install;

COPY ./docker/run.sh /opt/run.sh

CMD ["bash", "/opt/run.sh"]
