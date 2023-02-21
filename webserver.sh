#!/bin/sh

# dependency: netcat
SHELL=/bin/sh
NETCAT="busybox nc"
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
    filename=${filename%%"%20"*}' '$suffix
    suffix=${filename#*"%20"}
  done

  if [ -f "$filename" ]; then
    printf "HTTP/1.1 200 OK\r\n"
# Check mime
    case "${filename##*.}" in
      "htm" | "html") mime="text/html";;
      "css") mime="text/css";;
      "js") mime="text/javascript";;
      "sh" | "txt") mime="text/plain";;
      "jpg" | "jpeg") mime="image/jpeg";;
      "png") mime="image/png";;
      "gif") mime="image/gif";;
      "wav") mime="audio/wav";;
      "ogg") mime="audio/ogg";;
      "mp3") mime="audio/mpeg";;
      "mp4") mime="video/mp4";;
      "json") mime="application/json";;
      "pdf") mime="application/pdf";;
      *) mime="application/octet-stream";;
    esac
    printf "Content-Type: $mime\r\n\r\n"
    cat "$filename"
    printf "\r\n"

# Optional directory index
  elif [ -d "$filename" ]; then
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: text/html\r\n\r\n"
    printf '<meta charset="utf-8">'
    upper_dir=${url%/*/}/
    ([ "$url" != '/' ] && printf "<a href=\"${upper_dir:-/}\">../</a><br/>") \
      || url=""
    IFS=$'\n'
    for i in $WEBROOT$url/*; do
      inner_html=${i#$WEBROOT$url/}
      [ -d "$inner_html" ] && inner_html="$inner_html/"
# Replace space with &nbsp;
      suffix=${inner_html#*' '}
      while [ "$inner_html" != "$suffix" ]; do
        inner_html=${inner_html%%' '*}'&nbsp;'$suffix
        suffix=${inner_html#*' '}
      done
      printf "<a href=\"${i#$WEBROOT}\">$inner_html</a><br/>\n"
    done
    IFS="$SAVEIFS"
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
    $NETCAT -lp $PORT -e $SHELL $0 serve
    [ "$?" = 1 ] && sleep 5
  done;
}

([ "$1" = "serve" ] && webserve) || listen
