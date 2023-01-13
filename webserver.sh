#!/bin/sh

# dependency: nc
SHELL=/bin/sh
PORT=8000
WEBROOT=.
SAVEIFS=$IFS

webserve() {
  read request
  while true; do
    read header
    [ "$header" = "$(printf '\r')" ] && break;
  done

  url="${request#GET }"
  url="${url% HTTP/*}"
  filename="$WEBROOT$url"
# Replace %20 with <space>
  suffix=${filename#*"%20"}
  while [ "$filename" != "$suffix" ]; do
    prefix=${filename%%"%20"*}
    filename=$prefix' '$suffix
    suffix=${filename#*"%20"}
  done

  if [ -f "$filename" ]; then
    printf "HTTP/1.1 200 OK\r\n"

# Check mime
    ext=${filename##*.}
    mime="application/octet-stream"
    ([ "$ext" = htm ] || [ "$ext" = html ]) && mime="text/html"
    [ "$ext" = css ] && mime="text/css"
    [ "$ext" = js ] && mime="text/javascript"
    [ "$ext" = txt ] && mime="text/plain"
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
    IFS=$'\n'
    for i in $(ls -w 1 -p $WEBROOT$url); do
      inner_html=$i
# Replace <space> with &nbsp;
      suffix=${inner_html#*' '}
      while [ "$inner_html" != "$suffix" ]; do
        prefix=${inner_html%%' '*}
        inner_html=$prefix'&nbsp;'$suffix
        suffix=${inner_html#*' '}
      done
      printf "<a href=\"$url$i\">$inner_html</a><br/>\n"
    done
    IFS=$SAVEIFS
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
