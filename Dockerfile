FROM alpine:3.6
RUN addgroup -g 1000 -S bashttpd && \
    adduser -u 1000 -S bashttpd -G bashttpd
WORKDIR /home/bashttpd
RUN apk add --no-cache bash socat
COPY . .
USER bashttpd
CMD ["socat", "TCP4-LISTEN:8080,fork", "EXEC:./bashttpd"]
