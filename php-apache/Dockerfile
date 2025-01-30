FROM php:8.1-apache
LABEL maintainer="Björn Bores <bjalbor@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/bjalbor/wbce-docker"

ENV WBCE_VERSION=1.6.3

# Make sure, the upstream image is uptodate
RUN apt-get update && apt-get -y upgrade && apt-get clean

# Install wget to fetch WBCE package and libraries for gd
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        locales \
        locales-all \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
	wget

# Install SQL prerequisites for WBCE
RUN docker-php-ext-install mysqli && \
    docker-php-ext-enable mysqli

# Install php modules for gd
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) gd

# We need wait-for-it to avoid race conditions in docker
RUN curl -o /wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh
RUN chmod +x /wait-for-it.sh

COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh
COPY save.patch /

RUN a2enmod rewrite

# Default to German
ENV LC_ALL de_DE.UTF-8
ENV LANG de_DE.UTF-8

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
