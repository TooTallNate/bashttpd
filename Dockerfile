FROM alpine:3.6
RUN addgroup -g 1000 -S bashttpd && \
    adduser -u 1000 -S bashttpd -G bashttpd
RUN apk add --no-cache bash socat
WORKDIR /etc/bashttpd
COPY bashttpd /usr/bin/
COPY bashttpd.conf .
ENV BASHTTPD_CONFIG /etc/bashttpd/bashttpd.conf
USER bashttpd
EXPOSE 8080
CMD ["socat", "TCP4-LISTEN:8080,fork", "EXEC:bashttpd"]
