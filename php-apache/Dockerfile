FROM php:8.1-apache
LABEL maintainer="Björn Bores <bjalbor@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/bjalbor/wbce-docker"

ENV WBCE_VERSION=1.6.3

# Make sure, the upstream image is uptodate
RUN apt-get update && apt-get -y upgrade && apt-get clean

# Install wget to fetch WBCE package
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
	wget 

# Install prerequisites for WBCE
RUN docker-php-ext-install mysqli && \
    docker-php-ext-enable mysqli

RUN curl -o /wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh
RUN chmod +x /wait-for-it.sh

COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh
COPY save.patch /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2-foreground"] 
