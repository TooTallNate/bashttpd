FROM ubuntu
RUN apt-get update && apt-get install -y socat
WORKDIR /app
COPY . .
EXPOSE 8080
CMD socat TCP4-LISTEN:8080,fork EXEC:$PWD/bashttpd
