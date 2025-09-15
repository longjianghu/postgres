FROM postgres:17.6

# Install dependencies for zhparser
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libpq-dev \
    postgresql-server-dev-$PG_MAJOR \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install SCWS (Simple Chinese Word Segmentation)
RUN wget -q -O /tmp/scws-1.2.3.tar.bz2 http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2 \
    && cd /tmp \
    && tar -xjf scws-1.2.3.tar.bz2 \
    && cd scws-1.2.3 \
    && ./configure \
    && make install \
    && cd .. \
    && rm -rf scws-1.2.3 \
    && rm /tmp/scws-1.2.3.tar.bz2

# Clone and install zhparser
RUN git clone https://github.com/amutu/zhparser.git \
    && cd zhparser \
    && make && make install \
    && cd .. \
    && rm -rf zhparser

# Copy entrypoint script to initialize zhparser
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/