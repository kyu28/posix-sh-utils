# posix-shell-scripts
Some POSIX Shell scripts to maintain system

## perfset
A performance mode setting script

## vol.sh
A volume setting script

## status.sh
A status bar script, design for dwm

## webserver.sh
A script that start a webserver with file index, requires netcat or socat

## sfm.sh - simple file manager
A simple file manager script, inspired by nnn and fff

Usage:
- Navigate - up and down key
- Go to parent directory - left key
- Go into highlighted directory - right key
- Delete highlighted file or directory - x
- Rename or move highlighted file or directory - r
- Mark or unmark a file or directory - space
- Copy marked files and directories to current directory - p
- Move marked files and directories to current directory - v
- Quit sfm - q

Tips:
To enable cd on exit, add
```
sfm() {
  /bin/sfm # path to your sfm
  cd $(cat $HOME/.sfm_path)
}
```
to your ~/.bashrc or ~/.zshrc file

Known issue:
- Careful with filenames contain `*`

## svi.sh - simple vi
A functionless simple vi editor implementation

Usage:
- At normal mode
  - Delete one line - D
  - Clear one line and enter insert mode - S
  - New line below cursor and enter insert mode - o
  - New line above cursor and enter insert mode - O
  - Enter command mode - :
- At insert mode
  - Return to normal mode - Esc
- At command mode
  - Return to normal mode - Esc
  - Give up all the changes and reopen file - :e
  - Write changes - :w
  - Quit svi without saving - :q
  - Write changes and quit svi - :wq
