#!/bin/sh
# svi - simple vi

svi_width=80
svi_height=24
svi_mode=0 # 0 Normal 1 Insert 2 Command
svi_buffer=""
svi_line=""
svi_page=""
svi_file=""
svi_start=1
svi_row_num=0
svi_cursor_y=1
svi_cursor_x=1
svi_saveifs="$IFS"
svi_ifs="$(printf '\r')"
svi_escape="$(printf '\033')"
svi_backspace="$(printf '\177')"

svi_init() {
  svi_oldifs="$IFS"
  svi_file="$1"
  svi_width=$(stty size)
  svi_height=${svi_width% *}
  svi_width=${svi_width#* }
  svi_load_file
  svi_load_page
  IFS=$svi_ifs
  clear
}

svi_load_file() {
  svi_buffer=""
  while IFS= read svi_line; do
    svi_buffer="$svi_buffer""$svi_line"$svi_ifs
  done < "$svi_file"
  IFS="$svi_ifs"
  svi_buffer=${svi_buffer%"$IFS"}
}

svi_newline() {
  svi_i=1
  svi_tmp=""
  for svi_line in $svi_buffer; do
    if [ $svi_i -eq $1 ]; then
      svi_tmp="$svi_tmp"' '"$IFS"
      svi_row_num=$(($svi_row_num + 1))
    fi
    svi_tmp="$svi_tmp""$svi_line""$IFS"
    svi_i=$(($svi_i + 1))
  done
  svi_buffer="$svi_tmp"
}

svi_replace_line() {
  svi_i=1
  svi_tmp=""
  for svi_line in $svi_buffer; do
    if [ $svi_i -eq $1 ]; then
      svi_tmp="$svi_tmp""$svi_line_buffer""$IFS"
    else
      svi_tmp="$svi_tmp""$svi_line""$IFS"
    fi
    svi_i=$(($svi_i + 1))
  done
  svi_buffer="$svi_tmp"
}

svi_delete_line() {
  svi_i=1
  svi_tmp=""
  for svi_line in $svi_buffer; do
    if [ $svi_i -ne $1 ]; then
      svi_tmp="$svi_tmp""$svi_line""$IFS"
      svi_row_num=$(($svi_row_num - 1))
    fi
    svi_i=$(($svi_i + 1))
  done
  svi_buffer="$svi_tmp"
}

svi_load_page() {
  svi_page=""
  svi_i=1
  for svi_line in $svi_buffer; do
    if [ $svi_i -ge $svi_start ] &&
       [ $svi_i -lt $(($svi_start + svi_height)) ]; then
      svi_page="$svi_page""$svi_line""$IFS"
    fi
    svi_i=$(($svi_i + 1))
  done
  svi_row_num=$(($svi_i - 1))
  while [ $svi_i -lt $svi_height ]; do
    svi_page=${svi_page}'~'"$IFS"
    svi_i=$(($svi_i + 1))
  done
  svi_page=${svi_page%"$IFS"}
}

svi_move_cursor() {
  if [ $svi_mode -ne 2 ]; then
    printf "\033[$svi_cursor_y;${svi_cursor_x}H"
  fi
}

svi_insert() {
  svi_line_buffer=""
  while read -rsn 1 svi_input; do
    case "$svi_input" in
      "$svi_escape")
        break;;
      '')
        svi_replace_line $(($svi_cursor_y + $svi_start - 1))
        svi_cursor_y=$(($svi_cursor_y + 1))
        svi_cursor_x=0
        svi_newline $(($svi_cursor_y + $svi_start - 1))
        svi_load_page
        svi_print
        svi_status_line
        svi_move_cursor
        svi_line_buffer="";;
      "$svi_backspace")
        [ ${#svi_line_buffer} -gt 0 ] && printf "\033[D \033[D"
        svi_line_buffer="${svi_line_buffer%?}";;
      *)
        printf "%s" "$svi_input"
        svi_line_buffer="$svi_line_buffer""$svi_input";;
    esac
  done
  svi_replace_line $(($svi_cursor_y + $svi_start - 1))
  svi_cursor_x=$(($svi_cursor_x + ${#svi_line_buffer}))
  svi_mode=0
  svi_load_page
}

svi_write() {
  printf "" > ${1:-$svi_file}
  for svi_line in $svi_buffer; do
    printf "%s\n" "$svi_line" >> ${1:-$svi_file}
  done
  printf "\033[$svi_height;1H'$svi_file' ${svi_row_num}L"
}

svi_quit() {
  IFS=$svi_saveifs
  clear
  exit 0
}

svi_exec() {
  printf "\033[$svi_height;1H\033[2K"
  case "$1" in
    q)
      svi_quit;;
    w)
      svi_write;;
    e)
      svi_load_file
      svi_load_page;;
    wq)
      svi_write
      svi_quit;;
  esac
}

svi_command() {
  svi_cmd=""
  while read -rsn 1 svi_input; do
    case "$svi_input" in
      "$svi_escape")
        break;;
      '')
        svi_exec "$svi_cmd"
        break;;
      *)
       printf "%s" "$svi_input"
       svi_cmd="$svi_cmd""$svi_input";;
    esac
  done
  svi_mode=0
}

svi_status_line() {
  case $svi_mode in
    0)
      printf "\033[$svi_height;$(($svi_width - 15))H"
      printf "$(($svi_start + $svi_cursor_y - 1)),$svi_cursor_x $svi_input";;
    1)
      printf "\033[$svi_height;1H-- INSERT --"
      printf "\033[$svi_height;$(($svi_width - 15))H"
      printf "$(($svi_start + $svi_cursor_y - 1)),$svi_cursor_x $svi_input";;
    2)
      printf "\033[$svi_height;1H:";;
  esac
}

svi_print() {
  clear
  printf "\033[1;1H"
  svi_i=1
  for svi_line in $svi_page; do
    printf "$svi_line\n"
    svi_i=$(($svi_i + 1))
  done
}

svi_key_input() {
  read -rsn 1 svi_input
  [ "$svi_input" = "$svi_escape" ] && read -rsn 2 -t 0.01 svi_input
  case "$svi_input" in
    "$svi_escape")
      svi_mode=0;;
    '[A')
      if [ $svi_cursor_y -gt 1 ]; then
        svi_cursor_y=$(($svi_cursor_y - 1))
      elif [ $svi_start -gt 1 ]; then
        svi_start=$(($svi_start - 1))
        set -- $svi_buffer
        eval svi_line=\${$svi_start}
        svi_page="$svi_line""$IFS"${svi_page%"$IFS"*"$IFS"}"$IFS"
      fi;;
    '[B')
      if [ $svi_cursor_y -lt $(($svi_height - 1)) ]; then
        [ $svi_cursor_y -lt $svi_row_num ] && svi_cursor_y=$(($svi_cursor_y + 1))
      else
        if [ $(($svi_cursor_y + $svi_start - 1)) -lt $svi_row_num ]; then
          svi_start=$(($svi_start + 1))
          set -- $svi_buffer
          eval svi_line=\${$(($svi_cursor_y + $svi_start - 1))}
          svi_page="${svi_page#*"$IFS"}""$svi_line""$IFS"
        fi
      fi;;
    '[C')
      [ $svi_cursor_x -lt $svi_width ] && svi_cursor_x=$(($svi_cursor_x + 1));;
    '[D')
      [ $svi_cursor_x -gt 1 ] && svi_cursor_x=$(($svi_cursor_x - 1));;
    'o')
      svi_mode=1
      svi_cursor_x=0
      svi_cursor_y=$(($svi_cursor_y + 1))
      svi_newline $(($svi_cursor_y + $svi_start - 1))
      svi_load_page;;
    'O')
      svi_mode=1
      svi_cursor_x=0
      svi_newline $(($svi_cursor_y + $svi_start - 1))
      svi_load_page;;
    'D')
      svi_delete_line $(($svi_cursor_y + $svi_start - 1))
      svi_load_page;;
    'S')
      svi_mode=1
      svi_cursor_x=0
      svi_delete_line $(($svi_cursor_y + $svi_start - 1))
      svi_newline $(($svi_cursor_y + $svi_start - 1))
      svi_load_page;;
    ':')
      svi_mode=2;;
  esac
}

main() {
  svi_init "$1"
  trap '' INT # Do nothing when Ctrl+C
  while [ 0 ]; do
    svi_print
    svi_status_line
    svi_move_cursor
    case $svi_mode in
      0) svi_key_input;;
      1) svi_insert;;
      2) svi_command;;
    esac
  done
}

main "$@"
