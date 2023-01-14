#!/bin/sh
# sfm - simple file manager

sfm_cursor=1
sfm_height=0
sfm_files_num=0
sfm_cur_file=""
sfm_start=1
sfm_files=""
sfm_pwd=""
sfm_page=""
sfm_marked=""

sfm_init() {
  stty -echo # No echo
  printf "\033[?25l" # Hide cursor
  sfm_height=$(stty size) && sfm_height=${sfm_height%' '*}
  clear
}

sfm_quit() {
  stty echo
  printf "\033[?25h"
  clear
  echo $PWD > $HOME/.sfm_path
  exit 0
}

sfm_update() {
  if [ -n "$1" ]; then
    sfm_start=1
    sfm_cursor=1
  fi
  sfm_pwd=$PWD
  sfm_files=""
  sfm_page=""
  sfm_oldifs=$IFS
  IFS=$'\n'
  set -- $(ls -p -w1 $PWD)
  sfm_files_num=$#
  if [ $(($sfm_start + $sfm_cursor - 1)) -gt $sfm_files_num ]; then
    sfm_cursor=$(($sfm_height - 1))
    sfm_start=$(($sfm_files_num - $sfm_cursor + 1))
  fi
  sfm_i=1
  for sfm_file in $@; do
    sfm_files="$sfm_files""$sfm_file"$'\n'
    if [ $sfm_i -ge $sfm_start ] && [ $sfm_i -lt $(($sfm_start + $sfm_height - 1)) ]; then
      sfm_page="$sfm_page""$sfm_file"$'\n'
    fi
    sfm_i=$(($sfm_i + 1))
  done
  IFS=$sfm_oldifs
}

sfm_print() {
  clear
  printf "\033[1;1H"
  sfm_oldifs=$IFS
  IFS=$'\n'
  sfm_i=1
  for sfm_file in $sfm_page; do
    [ $sfm_i -eq $sfm_cursor ] && printf "\033[7m" && sfm_cur_file=${sfm_file%'/'}
    sfm_marked_flag=0
    for sfm_marked_file in $sfm_marked; do
      if [ "$PWD/${sfm_file%'/'}" = "$sfm_marked_file" ]; then
        sfm_marked_flag=1
        printf "+"
        break
      fi
    done
    [ $sfm_marked_flag -eq 0 ] && printf " "
    printf " $sfm_file\n"
    [ $sfm_i -eq $sfm_cursor ] && printf "\033[m"
    sfm_i=$((sfm_i + 1))
  done
  IFS=$sfm_oldifs
  printf "\033[$sfm_height;1H$PWD - $sfm_files_num files/directories"
}

sfm_key_input() {
  read -rsn 1 sfm_input
  [ "$sfm_input" = $'\033' ] && read -rsn 2 sfm_input
  case "$sfm_input" in
    'q') sfm_quit;;
    '[A')
      if [ $sfm_cursor -gt 1 ]; then
        sfm_cursor=$(($sfm_cursor - 1))
      elif [ $sfm_start -gt 1 ]; then
        sfm_start=$(($sfm_start - 1))
        sfm_oldifs=$IFS
        IFS=$'\n'
        set -- $sfm_files
        eval sfm_file=\${$sfm_start}
        sfm_page="$sfm_file"$'\n'"${sfm_page%$'\n'*$'\n'}"$'\n'
        IFS=$sfm_oldifs
      fi;;
    '[B')
      if [ $sfm_cursor -lt $(($sfm_height - 1)) ]; then
        [ $sfm_cursor -lt $sfm_files_num ] && sfm_cursor=$(($sfm_cursor + 1))
      else
        if [ $(($sfm_cursor + $sfm_start - 1)) -lt $sfm_files_num ]; then
          sfm_start=$(($sfm_start + 1))
          sfm_oldifs=$IFS
          IFS=$'\n'
          set -- $sfm_files
          eval sfm_file=\${$(($sfm_cursor + $sfm_start - 1))}
          sfm_page="${sfm_page#*$'\n'}""$sfm_file"$'\n'
          IFS=$sfm_oldifs
        fi
      fi;;
    '[C') [ -d $sfm_cur_file ] && cd $sfm_cur_file;;
    '[D') cd ..;;
    'x')
      printf "\033[$sfm_height;1H\033[2KDelete this file? (y/N)"
      read -rsn 1 sfm_input
      if [ $sfm_input = 'y' ]; then
        rm -rf "$sfm_cur_file"
        if [ $? -eq 0 ]; then
          sfm_update
        else
          printf "\033[$sfm_height;1H\033[2K$sfm_error" && sleep 3
        fi
      fi;;
    'r')
      printf "\033[$sfm_height;1H\033[2KNew path: \033[?25h"
      stty echo
      read sfm_input
      stty -echo
      printf "\033[?25l"
      if [ -n "$sfm_input" ]; then
        mv "$sfm_cur_file" "$sfm_input"
        if [ $? -eq 0 ]; then
          sfm_update
        else
          printf "\033[$sfm_height;1H\033[2K$sfm_error" && sleep 3
        fi
      fi;;
    '')
      sfm_oldifs=$IFS
      IFS=$'\n'
      sfm_marked_flag=0
      for sfm_marked_file in $sfm_marked; do
        [ "$PWD/${sfm_cur_file%'/'}" = "$sfm_marked_file" ] && sfm_marked_flag=1 && break
      done
      if [ $sfm_marked_flag -eq 0 ]; then
        sfm_marked="$sfm_marked""$PWD/${sfm_cur_file%'/'}"$'\n'
        printf "\033[$sfm_cursor;1H\033[7m+ $sfm_cur_file\n\033[m"
      else
        sfm_marked=${sfm_marked%"$sfm_marked_file"$'\n'*}${sfm_marked#*"$sfm_marked_file"$'\n'}
        printf "\033[$sfm_cursor;1H\033[7m  $sfm_cur_file\n\033[m"
      fi
      IFS=$sfm_oldifs;;
    'v')
      sfm_oldifs=$IFS
      IFS=$'\n'
      for sfm_marked_file in $sfm_marked; do
        mv "$sfm_marked_file" .
      done
      IFS=$sfm_oldifs
      sfm_marked=""
      sfm_update;;
    'p')
      sfm_oldifs=$IFS
      IFS=$'\n'
      for sfm_marked_file in $sfm_marked; do
        /bin/cp -rf "$sfm_marked_file" .
      done
      IFS=$sfm_oldifs
      sfm_marked=""
      sfm_update;;
    'd')
      printf "\033[$sfm_height;1H\033[2KDelete these files? (y/N)"
      read -rsn 1 sfm_input
      if [ $sfm_input = 'y' ]; then
        sfm_oldifs=$IFS
        IFS=$'\n'
        for sfm_marked_file in $sfm_marked; do
          rm -rf "$sfm_marked_file" .
        done
        IFS=$sfm_oldifs
        rm -rf "$sfm_marked"
        [ $? -ne 0 ] && sleep 3
        sfm_marked=""
        sfm_update
      fi;;
  esac
}

main() {
  sfm_init
  trap 'sfm_quit' 2 3 6 9 15 # INT QUIT ABRT KILL TERM
  while [ 0 ]; do # true
    [ "$sfm_pwd" != "$PWD" ] && sfm_update 1
    sfm_print
    sfm_key_input
  done
}

main "$@"
