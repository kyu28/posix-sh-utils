#!/bin/sh

# need busybox with nc
PORT=8000
WEBROOT=./

webserve() {
  read request
  while true; do
    read header
    [ "$header" = $'\r' ] && break;
  done

  url="${request#GET }"
  url="${url% HTTP/*}"
  filename="$WEBROOT$url"

  if [ -f "$filename" ]; then
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: $(file -bi \"$filename\")\r\n\r\n"
    cat "$filename"
    printf "\r\n"
  else
    printf "HTTP/1.1 404 Not Found\r\n"
    printf "Content-Type: text/html\r\n\r\n"
    printf "404 Not found\r\n\r\n"
  fi
}

listen() {
  printf "Listening at port $PORT..."
  while true; do
    busybox nc -lp $PORT -e ./webserver.sh serve
  done;
}

if [ "$1" = "start" ]; then
  listen
elif [ "$1" = "serve" ]; then
  webserve
else
  printf "Usage: webserver.sh start\n"
fi
