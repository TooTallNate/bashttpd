FROM alpine:3.6
RUN apk add --no-cache bash file socat sudo
WORKDIR /etc/bashttpd
COPY bashttpd /usr/bin/
COPY bashttpd.conf .
ENV BASHTTPD_CONFIG /etc/bashttpd/bashttpd.conf
EXPOSE 80
CMD ["socat", "TCP4-LISTEN:80,fork,reuseaddr", "EXEC:bashttpd"]
