FROM alpine:3.6
RUN apk add --no-cache bash socat
COPY . .
CMD ["socat", "TCP4-LISTEN:8080,fork", "EXEC:/bashttpd"]
