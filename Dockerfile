FROM alpine:3.6
RUN apk add --no-cache bash file socat sudo
WORKDIR /etc/bashttpd
COPY bashttpd /usr/bin/
COPY bashttpd.conf .
ENV BASHTTPD_CONFIG /etc/bashttpd/bashttpd.conf
EXPOSE 8080
CMD ["socat", "TCP4-LISTEN:8080,fork,reuseaddr", "EXEC:bashttpd"]
