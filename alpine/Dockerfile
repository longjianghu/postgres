FROM mysql:8.4.1

LABEL maintainer="Longjianghu <215241062@qq.com>"

FROM postgres:17.6-alpine3.22 AS builder

# Install build dependencies
RUN apk add --no-cache \
    alpine-sdk \
    git \
    postgresql-dev \
    wget

# Install SCWS (Simple Chinese Word Segmentation)
RUN wget -q -O /tmp/scws-1.2.3.tar.bz2 http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2 \
    && cd /tmp \
    && tar -xjf scws-1.2.3.tar.bz2 \
    && cd scws-1.2.3 \
    && ./configure --prefix=/usr \
    && make install \
    && cd .. \
    && rm -rf scws-1.2.3 \
    && rm /tmp/scws-1.2.3.tar.bz2

# Clone and build zhparser
RUN git clone https://github.com/amutu/zhparser.git \
    && cd zhparser \
    && sed -i 's/with_llvm\t= yes/with_llvm\t= no/g' /usr/local/lib/postgresql/pgxs/src/makefiles/../../src/Makefile.global \
    && sed -i 's/CLANG = clang-19/#CLANG = clang-19/g' /usr/local/lib/postgresql/pgxs/src/makefiles/../../src/Makefile.global \
    && SCWS_HOME=/usr make USE_PGXS=1 && make USE_PGXS=1 install \
    && cd .. \
    && rm -rf zhparser

# Create minimal image
FROM postgres:17.6-alpine3.22

# Install runtime dependencies
RUN apk add --no-cache \
    curl

# Copy built files from builder stage
COPY --from=builder /usr/lib/libscws.so.1.1.0 /usr/lib/
COPY --from=builder /usr/lib/libscws.so.1 /usr/lib/
COPY --from=builder /usr/lib/libscws.so /usr/lib/
COPY --from=builder /usr/local/lib/postgresql/zhparser.so /usr/local/lib/postgresql/zhparser.so
COPY --from=builder /usr/local/share/postgresql/extension/zhparser.control /usr/local/share/postgresql/extension/
COPY --from=builder /usr/local/share/postgresql/extension/zhparser--*.sql /usr/local/share/postgresql/extension/
COPY --from=builder /usr/local/share/postgresql/tsearch_data/dict.utf8.xdb /usr/local/share/postgresql/tsearch_data/
COPY --from=builder /usr/local/share/postgresql/tsearch_data/rules.utf8.ini /usr/local/share/postgresql/tsearch_data/

# Create symlinks for libscws
RUN ln -sf /usr/lib/libscws.so.1.1.0 /usr/lib/libscws.so.1 \
    && ln -sf /usr/lib/libscws.so.1.1.0 /usr/lib/libscws.so

# Copy entrypoint script to initialize zhparser
COPY init-zhparser.sh /docker-entrypoint-initdb.d/