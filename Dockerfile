FROM ubuntu:16.04
MAINTAINER Colin Broderick <colin@cbroderick.me>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
  apt-get install -y --no-install-recommends software-properties-common && \
  add-apt-repository ppa:ubuntugis/ubuntugis-unstable && \
  apt-get update && \
  apt-get upgrade -y


RUN apt-get install -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    gdal-bin \
    git \
    libgdal-dev \
    lsb-release \
    python-dev \
    python-pip \
    python-setuptools \
    python-wheel \
    software-properties-common \
    wget

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
  apt-key add -

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/postgresql.list

RUN apt-get update

# using postgres 9.5 and postgis 2.2 for sake of being easy
RUN apt-get install --no-install-recommends -y \
  postgis \
  "postgresql-9.5-postgis-2.3" \
    "postgresql-9.5-postgis-scripts" \
    "postgresql-contrib-9.5"

# add the user
USER postgres
RUN /etc/init.d/postgresql start && \
  psql --command "CREATE USER wwwdata WITH SUPERUSER PASSWORD 'password';" && \
  createdb -T template0 osmtm -E UTF8 -O wwwdata && \
  psql -d osmtm -c "CREATE EXTENSION postgis;"

USER root
# clone down the tm repo
RUN git clone --recursive git://github.com/hotosm/osm-tasking-manager2.git && cd osm-tasking-manager2

WORKDIR osm-tasking-manager2
RUN easy_install virtualenv
RUN virtualenv --no-site-packages env
RUN ./env/bin/pip install -r requirements.txt

COPY ./local.ini ./local.ini
RUN /etc/init.d/postgresql start && ./env/bin/initialize_osmtm_db

EXPOSE 6543

CMD /etc/init.d/postgresql start; /osm-tasking-manager2/env/bin/pserve --reload /osm-tasking-manager2/development.ini
