#!/bin/sh
# fm - file manager

fm_cursor=1
fm_height=0
fm_files_num=0
fm_cur_file=""
fm_start=1
fm_files=""
fm_pwd=""
fm_page=""
fm_marked=""
fm_ls_param=""
FM_ESCAPE="$(printf '\033')"
FM_SAVEIFS=$IFS
IFS=$'\n'

fm_init() {
  stty -echo # No echo
  printf "\033[?25l" # Hide cursor
  fm_height=$(stty size) && fm_height=${fm_height%' '*}
  [ "$1" = "-a" ] && fm_ls_param="-a"
  clear
}

fm_quit() {
  stty echo
  printf "\033[?25h"
  IFS=$FM_SAVEIFS
  clear
  echo $PWD > $HOME/.fm_path
  exit 0
}

fm_update() {
  if [ -n "$1" ]; then
    fm_start=1
    fm_cursor=1
  fi
  fm_pwd=$PWD
  set -- ${fm_ls_param:+.?*} * # .?* excludes .
  fm_files_num=$#
  if [ $(($fm_start + $fm_cursor - 1)) -gt $fm_files_num ]; then
    fm_cursor=$(($fm_height - 1 < $fm_files_num ? $fm_height - 1 : $fm_files_num))
    fm_start=$(($fm_files_num - $fm_cursor + 1))
  fi
  fm_i=1
  fm_files=""
  fm_page=""
  for fm_file in $@; do
    if ([ ! -h "$fm_file" ] && [ ! -e "$fm_file" ]) || [ "$fm_file" = ".." ]; then
      fm_files_num=$(($fm_files_num - 1))
      continue
    fi
    [ -d "$fm_file" ] && fm_file="$fm_file/"
    fm_files="$fm_files""$fm_file"$IFS
    if [ $fm_i -ge $fm_start ] && [ $fm_i -lt $(($fm_start + $fm_height - 1)) ]; then
      fm_page="$fm_page""$fm_file"$IFS
    fi
    fm_i=$(($fm_i + 1))
  done
}

fm_print() {
  clear
  printf "\033[1;1H"
  fm_i=1
  for fm_file in $fm_page; do
    [ $fm_i -eq $fm_cursor ] && printf "\033[7m" && fm_cur_file=$fm_file
    fm_marked_sign=" "
    for fm_marked_file in $fm_marked; do
      if [ "$PWD/$fm_file" = "$fm_marked_file" ]; then
        fm_marked_sign="+"
        break
      fi
    done
    echo "$fm_marked_sign $fm_file"
    [ $fm_i -eq $fm_cursor ] && printf "\033[m"
    fm_i=$((fm_i + 1))
  done
  printf "\033[$fm_height;1H$PWD - $fm_files_num files/directories"
}

fm_key_input() {
  read -rn 1 fm_input
  while [ "$fm_input" = "$FM_ESCAPE" ]; do
    read -rn 1 fm_input
    [ "$fm_input" = '[' ] && read -rn 1 fm_input && fm_input='['$fm_input
    [ "$fm_input" = 'O' ] && read -rn 1 fm_input && fm_input='O'$fm_input # F Keys
  done
  case "$fm_input" in
    'q') fm_quit;;
    '[A')
      if [ $fm_cursor -gt 1 ]; then
        fm_cursor=$(($fm_cursor - 1))
      elif [ $fm_start -gt 1 ]; then
        fm_start=$(($fm_start - 1))
        set -- $fm_files
        eval fm_file=\${$fm_start}
        fm_page="$fm_file""$IFS""${fm_page%$IFS*$IFS}"$IFS
      fi;;
    '[B')
      if [ $fm_cursor -lt $(($fm_height - 1)) ]; then
        [ $fm_cursor -lt $fm_files_num ] && fm_cursor=$(($fm_cursor + 1))
      else
        if [ $(($fm_cursor + $fm_start - 1)) -lt $fm_files_num ]; then
          fm_start=$(($fm_start + 1))
          set -- $fm_files
          eval fm_file=\${$(($fm_cursor + $fm_start - 1))}
          fm_page=${fm_page#*"$IFS"}"$fm_file""$IFS"
        fi
      fi;;
    '[C') [ -d "$fm_cur_file" ] && cd "$fm_cur_file";;
    '[D') cd ..;;
    'x')
      printf "\033[$fm_height;1H\033[2KDelete this file? (y/N)"
      read -rn 1 fm_input
      if [ $fm_input = 'y' ]; then
        rm -rf $fm_cur_file
        if [ $? -eq 0 ]; then
          fm_update
        else
          sleep 3
        fi
      fi;;
    'r')
      printf "\033[$fm_height;1H\033[2KNew path: \033[?25h"
      stty echo
      read fm_input
      stty -echo
      printf "\033[?25l"
      if [ -n "$fm_input" ]; then
        mv $fm_cur_file $fm_input
        if [ $? -eq 0 ]; then
          fm_update
        else
          sleep 3
        fi
      fi;;
    ' ')
      fm_marked_sign=" "
      for fm_marked_file in $fm_marked; do
        [ "$PWD/$fm_cur_file" = "$fm_marked_file" ] && fm_marked_sign="+" && break
      done
      if [ "$fm_marked_sign" = " " ]; then # toggle marked status
        fm_marked="$fm_marked""$PWD/$fm_cur_file""$IFS"
      else
        fm_marked=${fm_marked%"$fm_marked_file""$IFS"*}${fm_marked#*"$fm_marked_file""$IFS"}
      fi
      printf "\033[$fm_cursor;1H\033[7m$fm_marked_sign\033[m";;
    'v')
      mv $fm_marked .
      fm_marked=""
      fm_update;;
    'p')
      /bin/cp -rf $fm_marked . # Careful with *
      fm_marked=""
      fm_update;;
    'd')
      printf "\033[$fm_height;1H\033[2KDelete these files? (y/N)"
      read -rn 1 fm_input
      if [ $fm_input = 'y' ]; then
        rm -rf $fm_marked
        [ $? -ne 0 ] && sleep 3
        fm_marked=""
        fm_update
      fi;;
    'm')
      printf "\033[$fm_height;1H\033[2KNew directory name: \033[?25h"
      stty echo
      read fm_input
      stty -echo
      printf "\033[?25l"
      if [ -n "$fm_input" ]; then
        mkdir "$fm_input"
        if [ $? -eq 0 ]; then
          fm_update
        else
          sleep 3
        fi
      fi;;
  esac
}

main() {
  fm_init "$@"
  trap 'fm_quit' 2 3 6 9 15 # INT QUIT ABRT KILL TERM
  while [ 0 ]; do # true
    [ "$fm_pwd" != "$PWD" ] && fm_update 1
    fm_print
    fm_key_input
  done
}

main "$1"
