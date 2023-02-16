#!/bin/sh
# vi - simple vi

vi_width=80
vi_height=24
vi_mode=0 # 0 Normal 1 Insert 2 Command
vi_buffer=""
vi_line=""
vi_page=""
vi_file=""
vi_start=1
vi_row_num=0
vi_cursor_y=1
vi_cursor_x=1
vi_saveifs="$IFS"
VI_IFS="$(printf '\r')"
VI_ESCAPE="$(printf '\033')"
VI_BACKSPACE="$(printf '\177')"

vi_init() {
  trap '' 2 # SIGINT Do nothing when Ctrl+C
  vi_oldifs="$IFS"
  vi_file="$1"
  vi_width=$(stty size)
  vi_height=${vi_width% *}
  vi_width=${vi_width#* }
  stty -echo
  vi_load_file
  vi_load_page
  IFS=$VI_IFS
  clear
}

vi_quit() {
  IFS=$vi_saveifs
  stty echo
  clear
  exit 0
}

vi_load_file() {
  vi_buffer=""
  if [ -f "$vi_file" ]; then
    while IFS= read vi_line; do
      vi_buffer="$vi_buffer$vi_line$VI_IFS"
    done < "$vi_file"
    IFS="$VI_IFS"
  fi
}

vi_load_page() {
  vi_page=""
  vi_row_num=1
  vi_i=0 # page row num
  for vi_line in $vi_buffer; do
    if [ $vi_row_num -ge $vi_start ] &&
       [ $vi_row_num -lt $(($vi_start + $vi_height - 1)) ]; then
      vi_page="$vi_page$vi_line$IFS"
      vi_i=$(($vi_i + 1))
    fi
    vi_row_num=$(($vi_row_num + 1))
  done
  vi_row_num=$(($vi_row_num - 1))
  while [ $vi_i -lt $((vi_height - 1)) ]; do
    vi_page="${vi_page}~$IFS"
    vi_i=$(($vi_i + 1))
  done
}

vi_newline() {
  vi_i=1
  vi_tmp=""
  [ $vi_row_num -eq 0 ] && vi_row_num=1 && vi_buffer=" $IFS"
  for vi_line in $vi_buffer; do
    if [ $vi_i -eq $1 ]; then
      vi_tmp="$vi_tmp $IFS"
      vi_row_num=$(($vi_row_num + 1))
    fi
    vi_tmp="$vi_tmp$vi_line$IFS"
    vi_i=$(($vi_i + 1))
  done
  if [ $vi_i -eq $1 ]; then
    vi_tmp="$vi_tmp"' '"$IFS"
    vi_row_num=$(($vi_row_num + 1))
  fi
  vi_buffer="$vi_tmp"
}

vi_replace_line() {
  vi_i=1
  vi_tmp=""
  for vi_line in $vi_buffer; do
    if [ $vi_i -eq $1 ]; then
      vi_tmp="$vi_tmp$vi_line_buffer$IFS"
    else
      vi_tmp="$vi_tmp$vi_line$IFS"
    fi
    vi_i=$(($vi_i + 1))
  done
  vi_buffer="$vi_tmp"
}

vi_delete_line() {
  vi_i=1
  vi_tmp=""
  for vi_line in $vi_buffer; do
    if [ $vi_i -ne $1 ]; then
      vi_tmp="$vi_tmp$vi_line$IFS"
    fi
    vi_i=$(($vi_i + 1))
  done
  vi_row_num=$(($vi_row_num - 1))
  vi_buffer="$vi_tmp"
}

vi_insert() {
  vi_line_buffer=""
  while read -rn 1 vi_input; do
    case "$vi_input" in
      "$VI_ESCAPE")
        break;;
      '')
        vi_replace_line $(($vi_cursor_y + $vi_start - 1))
        vi_cursor_y=$(($vi_cursor_y + 1))
        vi_cursor_x=0
        vi_newline $(($vi_cursor_y + $vi_start - 1))
        vi_load_page
        vi_print
        vi_status_line
        printf "\033[$vi_cursor_y;${vi_cursor_x}H"
        vi_line_buffer="";;
      "$VI_BACKSPACE")
        [ ${#vi_line_buffer} -gt 0 ] && printf "\033[D \033[D"
        vi_line_buffer="${vi_line_buffer%?}";;
      *)
        printf "%s" "$vi_input"
        vi_line_buffer="$vi_line_buffer""$vi_input";;
    esac
  done
  vi_replace_line $(($vi_cursor_y + $vi_start - 1))
  vi_cursor_x=$(($vi_cursor_x + ${#vi_line_buffer}))
  vi_mode=0
  vi_load_page
}

vi_write() {
  > "$vi_file" # touch
  for vi_line in $vi_buffer; do
    echo "$vi_line" >> "$vi_file"
  done
  printf "\033[$vi_height;1H'$vi_file' ${vi_row_num}L"
}

vi_exec() {
  printf "\033[$vi_height;1H\033[2K"
  case "$1" in
    q) vi_quit;;
    w) vi_write;;
    e)
      vi_load_file
      vi_load_page;;
    wq)
      vi_write
      vi_quit;;
  esac
}

vi_command() {
  vi_cmd=""
  while read -rn 1 vi_input; do
    case "$vi_input" in
      "$VI_ESCAPE")
        break;;
      '')
        vi_exec $vi_cmd
        break;;
      "$VI_BACKSPACE")
        [ ${#vi_cmd} -gt 0 ] && printf "\033[D \033[D"
        vi_cmd="${vi_cmd%?}";; # Remove last char
      *)
       printf "%s" "$vi_input"
       vi_cmd="$vi_cmd""$vi_input";;
    esac
  done
  vi_mode=0
}

vi_status_line() {
  case $vi_mode in
    0 | 1)
      [ $vi_mode -eq 1 ] && printf "\033[$vi_height;1H-- INSERT --"
      printf "\033[$vi_height;$(($vi_width - 15))H"
      printf "$(($vi_start + $vi_cursor_y - 1)),$vi_cursor_x";;
    2) printf "\033[$vi_height;1H:";;
  esac
}

vi_print() {
  clear
  printf "\033[1;1H"
  for vi_line in $vi_page; do
    echo "$vi_line"
  done
}

vi_key_input() {
  read -rn 1 vi_input
  while [ "$vi_input" = "$VI_ESCAPE" ]; do # special keys and F keys
    read -rn 1 vi_input
    [ "$vi_input" = '[' ] && read -rn 1 vi_input && vi_input='['$vi_input
    [ "$vi_input" = 'O' ] && read -rn 1 vi_input && vi_input='O'$vi_input
  done
  case "$vi_input" in
    '[A' | 'k')
      if [ $vi_cursor_y -gt 1 ]; then
        vi_cursor_y=$(($vi_cursor_y - 1))
      elif [ $vi_start -gt 1 ]; then
        vi_start=$(($vi_start - 1))
        set -- $vi_buffer
        eval vi_line=\${$vi_start}
        vi_page="$vi_line$IFS${vi_page%$IFS*$IFS}$IFS"
      fi;;
    '[B' | 'j')
      if [ $vi_cursor_y -lt $(($vi_height - 1)) ]; then
        [ $vi_cursor_y -lt $vi_row_num ] && vi_cursor_y=$(($vi_cursor_y + 1))
      elif [ $(($vi_cursor_y + $vi_start - 1)) -lt $vi_row_num ]; then
        vi_start=$(($vi_start + 1))
        set -- $vi_buffer
        eval vi_line=\${$(($vi_cursor_y + $vi_start - 1))}
        vi_page="${vi_page#*$IFS}$vi_line$IFS"
      fi;;
    '[C' | 'l')
      [ $vi_cursor_x -lt $vi_width ] && vi_cursor_x=$(($vi_cursor_x + 1));;
    '[D' | 'h')
      [ $vi_cursor_x -gt 1 ] && vi_cursor_x=$(($vi_cursor_x - 1));;
    'o' | 'O' | 'S')
      vi_mode=1
      vi_cursor_x=0
      if [ "$vi_input" = 'o' ]; then
        if [ $vi_cursor_y -lt $((vi_height - 1)) ]; then
          vi_cursor_y=$(($vi_cursor_y + 1))
        else
          vi_start=$((vi_start + 1))
          vi_page="${vi_page#*"$IFS"}"
        fi
      fi
      [ "$vi_input" = 'S' ] && vi_delete_line $(($vi_cursor_y + $vi_start - 1))
      vi_newline $(($vi_cursor_y + $vi_start - 1))
      vi_load_page;;
    'D')
      vi_delete_line $(($vi_cursor_y + $vi_start - 1))
      if [ $(($vi_cursor_y + $vi_start - 1)) -gt $vi_row_num ]; then
        vi_cursor_y=$(($vi_row_num - $vi_start + 1))
      fi
      vi_load_page;;
    ':')
      vi_mode=2;;
  esac
}

main() {
  [ -z "$1" ] && echo "$0: no filename" && exit 1
  vi_init "$1"
  while [ 0 ]; do
    vi_print
    vi_status_line
    [ $vi_mode -ne 2 ] && printf "\033[$vi_cursor_y;${vi_cursor_x}H"
    case $vi_mode in
      0) vi_key_input;;
      1) vi_insert;;
      2) vi_command;;
    esac
  done
}

main "$@"
