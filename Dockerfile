FROM alpine:3.6
RUN addgroup -g 1000 -S bashttpd && \
    adduser -u 1000 -S bashttpd -G bashttpd
RUN apk add --no-cache bash socat
USER bashttpd
WORKDIR /home/bashttpd
COPY . .
EXPOSE 8080
CMD ["socat", "TCP4-LISTEN:8080,fork", "EXEC:./bashttpd"]
