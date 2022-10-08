#!/bin/sh

# dependency: nc
SHELL=/bin/sh
PORT=8000
WEBROOT=.

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

# Check mime
    ext=${filename##*.}
    mime="application/octet-stream"
    ([ "$ext" = htm ] || [ "$ext" = html ]) && mime="text/html"
    [ "$ext" = css ] && mime="text/css"
    [ "$ext" = js ] && mime="text/javascript"
    ([ "$ext" = jpg ] || [ "$ext" = jpeg ]) && mime="image/jpeg"
    [ "$ext" = png ] && mime="image/png"
    [ "$ext" = gif ] && mime="image/gif"
    [ "$ext" = wav ] && mime="audio/wav"
    [ "$ext" = ogg ] && mime="audio/ogg"
    [ "$ext" = mp3 ] && mime="audio/mpeg"
    [ "$ext" = mp4 ] && mime="video/mp4"
    [ "$ext" = json ] && mime="application/json"
    [ "$ext" = pdf ] && mime="application/pdf"
    printf "Content-Type: $mime\r\n\r\n"

    cat "$filename"
    printf "\r\n"

# Optional directory index
  elif dirCheck="$(ls -d -p $filename)" \
       && [ ${dirCheck%/} != $dirCheck ]; then
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: text/html\r\n\r\n"
    printf "<meta charset=\"utf-8\">"
    upperDir=${url%/*/}/
    [ "$url" != '/' ]  && printf "<a href=\"${upperDir:-/}\">../</a><br/>"
  # Known issue: Cannot correctly parse filename with space
    for i in $(ls -p $WEBROOT$url); do
      printf "<a href=\"$url$i\">$i</a><br/>\n"
    done
    printf "\r\n"
# End of directory index
  else
    printf "HTTP/1.1 404 Not Found\r\n"
    printf "Content-Type: text/html\r\n\r\n"
    printf "404 Not found\r\n\r\n"
  fi
}

listen() {
  printf "Listening 0.0.0.0:$PORT"
  while true; do
    busybox nc -lp $PORT -e $SHELL $0 serve
    [ "$?" = 1 ] && sleep 5
  done;
}

if [ "$1" = "start" ]; then
  listen
elif [ "$1" = "serve" ]; then
  webserve
else
  printf "Simple web server\n\n"
  printf "Usage: $0 start\n"
fi
