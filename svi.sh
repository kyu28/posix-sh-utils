#!/bin/sh
# svi - simple vi

svi_width=80
svi_height=24
svi_mode=0 # 0 Normal 1 Insert 2 Command
svi_buffer=""
svi_line=""
svi_page=""
svi_file=""
svi_tmp=""
svi_start=1
svi_row_num=0
svi_cursor_y=1
svi_cursor_x=1

svi_init() {
  svi_oldifs=$IFS
  svi_file="$1"
  set -- $(stty size)
  svi_width=$2
  svi_height=$1
  svi_load_file
  svi_load_page
  IFS=$svi_oldifs
  clear
}

svi_load_file() {
  svi_buffer=""
  while IFS= read svi_line; do
    svi_buffer="$svi_buffer""$svi_line"$'\r'
  done < "$svi_file"
  svi_buffer=${svi_buffer%$'\r'}
}

svi_newline() {
  svi_oldifs=$IFS
  IFS=$'\r'
  svi_i=1
  svi_tmp=""
  for svi_line in $svi_buffer; do
    if [ $svi_i -eq $1 ]; then
      svi_tmp="$svi_tmp"$'\r'
    fi
    svi_tmp="$svi_tmp""$svi_line"$'\r'
    svi_i=$(($svi_i + 1))
  done
  svi_buffer=$svi_tmp
  IFS=$svi_oldifs
  svi_row_num=$(($svi_row_num + 1))
}

svi_replace_line() {
  svi_oldifs=$IFS
  IFS=$'\r'
  svi_i=1
  svi_tmp=""
  for svi_line in $svi_buffer; do
    if [ $svi_i -eq $1 ]; then
      svi_tmp="$svi_tmp""$svi_line_buffer"$'\r'
    else
      svi_tmp="$svi_tmp""$svi_line"$'\r'
    fi
    svi_i=$(($svi_i + 1))
  done
  svi_buffer=$svi_tmp
  IFS=$svi_oldifs
}

svi_delete_line() {
  svi_oldifs=$IFS
  IFS=$'\r'
  svi_i=1
  svi_tmp=""
  for svi_line in $svi_buffer; do
    [ $svi_i -ne $1 ] && svi_tmp="$svi_tmp""$svi_line"$'\r'
    svi_i=$(($svi_i + 1))
  done
  svi_buffer=$svi_tmp
  IFS=$svi_oldifs
  svi_row_num=$(($svi_row_num - 1))
}

svi_load_page() {
  svi_page=""
  svi_oldifs=$IFS
  IFS=$'\r'
  svi_i=1
  for svi_line in $svi_buffer; do
    if [ $svi_i -ge $svi_start ] &&
       [ $svi_i -lt $(($svi_start + svi_height)) ]; then
      svi_page="$svi_page""$svi_line"$'\r'
    fi
    svi_i=$(($svi_i + 1))
  done
  svi_row_num=$(($svi_i - 1))
  svi_page=${svi_page%$'\r'}
  IFS=$svi_oldifs
}

svi_move_cursor() {
  if [ $svi_mode -ne 2 ]; then
    printf "\033[$svi_cursor_y;${svi_cursor_x}H"
  fi
}

svi_insert() {
  IFS=$'\r'
  svi_line_buffer=""
  while read -rsn 1 svi_input; do
    case "$svi_input" in
      $'\033')
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
      $'\177') # Backspace
        [ ${#svi_line_buffer} -gt 0 ] && printf "\033[D \033[D"
        svi_line_buffer="${svi_line_buffer%?}";;
      *)
        printf "%s" "$svi_input"
        svi_line_buffer="$svi_line_buffer""$svi_input";;
    esac
  done
  IFS=$svi_oldifs
  svi_replace_line $(($svi_cursor_y + $svi_start - 1))
  svi_cursor_x=$(($svi_cursor_x + ${#svi_line_buffer}))
  svi_mode=0
  svi_load_page
}

svi_write() {
  svi_oldifs=$IFS
  IFS=$'\r'
  printf "" > ${1:-$svi_file}
  for svi_line in $svi_buffer; do
    printf "%s\n" "$svi_line" >> ${1:-$svi_file}
  done
  IFS=$svi_oldifs
  printf "\033[$svi_height;1H'$svi_file' ${svi_row_num}L"
}

svi_quit() {
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
      svi_load_file;;
    wq)
      svi_write
      svi_quit;;
  esac
}

svi_command() {
  svi_oldifs=$IFS
  svi_cmd=""
  IFS=$'\r'
  while read -rsn 1 svi_input; do
    case "$svi_input" in
      $'\033')
        break;;
      '')
        svi_exec "$svi_cmd"
        break;;
      *)
       printf "%s" "$svi_input"
       svi_cmd="$svi_cmd""$svi_input";;
    esac
  done
  IFS=$svi_oldifs
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
  svi_oldifs=$IFS
  IFS=$'\r'
  svi_i=1
  for svi_line in $svi_page; do
    printf "$svi_line\n"
    svi_i=$(($svi_i + 1))
  done
  IFS=$svi_oldifs
}

svi_key_input() {
  svi_oldifs=$IFS
  IFS=$'\r'
  read -rsn 1 svi_input
  [ "$svi_input" = $'\033' ] && read -rsn 2 -t 0.01 svi_input
  case "$svi_input" in
    $'\033') # ESC
     svi_mode=0;;
    '[A')
      if [ $svi_cursor_y -gt 1 ]; then
        svi_cursor_y=$(($svi_cursor_y - 1))
      elif [ $svi_start -gt 1 ]; then
        svi_start=$(($svi_start - 1))
        svi_oldifs=$IFS
        IFS=$'\r'
        set -- $svi_buffer
        eval svi_line=\${$svi_start}
        svi_page="$svi_line"$'\r'"${svi_page%$'\r'*$'\r'}"$'\r'
        IFS=$svi_oldifs
      fi;;
    '[B')
      if [ $svi_cursor_y -lt $(($svi_height - 1)) ]; then
        [ $svi_cursor_y -lt $svi_row_num ] && svi_cursor_y=$(($svi_cursor_y + 1))
      else
        if [ $(($svi_cursor_y + $svi_start - 1)) -lt $svi_row_num ]; then
          svi_start=$(($svi_start + 1))
          svi_oldifs=$IFS
          IFS=$'\r'
          set -- $svi_buffer
          eval svi_line=\${$(($svi_cursor_y + $svi_start - 1))}
          svi_page="${svi_page#*$'\r'}""$svi_line"$'\r'
          IFS=$svi_oldifs
        fi
      fi;;
    '[C')
      [ $svi_cursor_x -lt $svi_width ] && svi_cursor_x=$(($svi_cursor_x + 1));;
    '[D')
      [ $svi_cursor_x -gt 1 ] && svi_cursor_x=$(($svi_cursor_x - 1));;
    'o')
      svi_mode=1
      svi_cursor_y=$(($svi_cursor_y + 1))
      svi_newline $(($svi_cursor_y + $svi_start - 1))
      svi_load_page;;
    'O')
      svi_mode=1
      svi_newline $(($svi_cursor_y + $svi_start - 1))
      svi_load_page;;
    'D')
      svi_delete_line $(($svi_cursor_y + $svi_start - 1))
      svi_load_page;;
    'S')
      svi_mode=1
      svi_delete_line $(($svi_cursor_y + $svi_start - 1))
      svi_newline $(($svi_cursor_y + $svi_start - 1))
      svi_load_page;;
    ':')
      svi_mode=2;;
  esac
  IFS=$svi_oldifs
}

main() {
  svi_init "$1"
  trap '' 2 # SIGINT Do nothing when Ctrl+C
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
