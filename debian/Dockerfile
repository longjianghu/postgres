FROM mysql:8.4.1

LABEL maintainer="Longjianghu <215241062@qq.com>"

FROM postgres:17.6 AS builder

# Install dependencies for building zhparser
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

# Clone and build zhparser
RUN git clone https://github.com/amutu/zhparser.git \
    && cd zhparser \
    && make && make install \
    && cd .. \
    && rm -rf zhparser

# Create minimal image
FROM postgres:17.6

# Install runtime dependencies for zhparser
RUN apt-get update && apt-get install -y \
    libcurl4t64 \
    && rm -rf /var/lib/apt/lists/*

# Copy built files from builder stage
COPY --from=builder /usr/local/lib/libscws.so.1.1.0 /usr/local/lib/
COPY --from=builder /usr/local/lib/libscws.so.1 /usr/local/lib/
COPY --from=builder /usr/local/lib/libscws.so /usr/local/lib/
COPY --from=builder /usr/lib/postgresql/$PG_MAJOR/lib/zhparser.so /usr/lib/postgresql/$PG_MAJOR/lib/
COPY --from=builder /usr/share/postgresql/$PG_MAJOR/extension/zhparser.control /usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=builder /usr/share/postgresql/$PG_MAJOR/extension/zhparser--*.sql /usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=builder /usr/share/postgresql/$PG_MAJOR/tsearch_data/dict.utf8.xdb /usr/share/postgresql/$PG_MAJOR/tsearch_data/
COPY --from=builder /usr/share/postgresql/$PG_MAJOR/tsearch_data/rules.utf8.ini /usr/share/postgresql/$PG_MAJOR/tsearch_data/

# Create symlinks for libscws
RUN ln -sf /usr/local/lib/libscws.so.1.1.0 /usr/local/lib/libscws.so.1 \
    && ln -sf /usr/local/lib/libscws.so.1.1.0 /usr/local/lib/libscws.so

# Update library cache
RUN ldconfig

# Copy entrypoint script to initialize zhparser
COPY init-zhparser.sh /docker-entrypoint-initdb.d/