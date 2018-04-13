FROM silph/php:7.0-fpm-xenial
MAINTAINER Martin Campbell <martin@campbellsoftware.co.uk>

# setup workdir
RUN mkdir /data
WORKDIR /data

# environment for osticket
ENV OSTICKET_VERSION 1.10.1
ENV HOME /data

# requirements and PHP extensions
RUN apt-get update && apt-get install -y \
    cron \
    wget \
    unzip \
    msmtp \
    ca-certificates \
    supervisor \
    nginx \
    libpng12-dev \
    libc-client2007e-dev \
    ldap-utils \
    libc6-dev \
    libxml2 \
    icu-devtools \
    libicu-dev \
    libicu55 \
    openssl \
    uw-mailutils \
    libpng-dev \
    libldap2-dev \
    libgettextpo-dev \
    libpcre3-dev \
    libpcre++-dev \
    libkrb5-dev \
    libxml2-dev \
    autoconf \
    g++ \
    make && \
    docker-php-ext-install gd curl mysqli sockets gettext mbstring xml intl opcache && \
    docker-php-ext-configure imap --with-imap-ssl --with-kerberos && \
    docker-php-ext-install imap && \
    pecl install apcu && docker-php-ext-enable apcu && \
    apt-get remove -y libc-client2007e-dev libpng12-dev libldap2-dev libgettextpo-dev libxml2-dev libicu-dev autoconf g++ make libpcre3-dev libpcre++-dev && \
    rm -rf /var/lib/apt/lists/*

# Download & install OSTicket
RUN wget -nv -O osTicket.zip http://osticket.com/sites/default/files/download/osTicket-v${OSTICKET_VERSION}.zip && \
    unzip osTicket.zip && \
    rm osTicket.zip && \
    chown -R www-data:www-data /data/upload/ && \
    chmod -R a+rX /data/upload/ /data/scripts/ && \
    chmod -R u+rw /data/upload/ /data/scripts/ && \
    mv /data/upload/setup /data/upload/setup_hidden && \
    chown -R root:root /data/upload/setup_hidden && \
    chmod 700 /data/upload/setup_hidden

# Download languages packs
RUN wget -nv -O upload/include/i18n/fr.phar http://osticket.com/sites/default/files/download/lang/fr.phar && \
    wget -nv -O upload/include/i18n/ar.phar http://osticket.com/sites/default/files/download/lang/ar.phar && \
    wget -nv -O upload/include/i18n/pt_BR.phar http://osticket.com/sites/default/files/download/lang/pt_BR.phar && \
    wget -nv -O upload/include/i18n/it.phar http://osticket.com/sites/default/files/download/lang/it.phar && \
    wget -nv -O upload/include/i18n/es_ES.phar http://osticket.com/sites/default/files/download/lang/es_ES.phar && \
    wget -nv -O upload/include/i18n/de.phar http://osticket.com/sites/default/files/download/lang/de.phar && \
    mv upload/include/i18n upload/include/i18n.dist

# Configure nginx, PHP, msmtp and supervisor
COPY nginx.conf /etc/nginx/nginx.conf
COPY php-osticket.ini $PHP_INI_DIR/conf.d/
RUN touch /var/log/msmtp.log && \
    chown www-data:www-data /var/log/msmtp.log
COPY supervisord.conf /data/supervisord.conf
COPY msmtp.conf /data/msmtp.conf
COPY php.ini $PHP_INI_DIR/php.ini

COPY bin/ /data/bin

COPY overrides/background2.jpg /data/upload/scp/images/login-headquarters.jpg
COPY overrides/L_SilphRoad_transparent.png /data/upload/scp/images/ost-logo.png
COPY overrides/login.css /data/upload/scp/css/login.css

VOLUME ["/data/upload/include/plugins","/data/upload/include/i18n","/var/log/nginx"]
EXPOSE 80
CMD ["/data/bin/start.sh"]
