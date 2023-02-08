# posix-sh-tools
Some POSIX Shell implemented tools

## Why POSIX Shell?
No compilation, maximum portability, almost no dependency.
POSIX Shell can run on almost every device such as your old PC, your unrooted Android phone and even your router.

## perfset
A performance mode setting script, design to recover the function of Fn+Q performance mode toggling on Lenovo laptop.

## vol.sh
A volume setting script  
Any volume change will refresh status.sh

## status
+ status.sh  
A status bar script, design for suckless's dwm  
Usage: `status.sh &` 
+ statuscli.sh  
Same status bar as above, design for tty  
Usage: `statuscli.sh &`

## webserver.sh
A script that start a webserver with file index, requires netcat or socat

## fm.sh - file manager
A simple file manager script, inspired by nnn and fff

Usage:  
`fm.sh [-a]`
- Navigate - up and down key
- Go to parent directory - left key
- Go into highlighted directory - right key
- Delete highlighted file or directory - x
- Rename or move highlighted file or directory - r
- Make a new directory - m
- Mark or unmark a file or directory - space
- Copy marked files and directories to current directory - p
- Move marked files and directories to current directory - v
- Quit fm - q
- To show hidden objects, use option `-a`

Tips:
To enable cd on exit, add
```
fm() {
  /bin/fm.sh "$@"  # path to your fm.sh
  cd $(cat $HOME/.fm_path)
  rm $HOME/.fm_path # Optional, delete path file
}
```
to your ~/.bashrc or ~/.zshrc file

Known issue:
- Careful with filenames contain `*`

## svi.sh - simple vi
A simple vi editor implementation


Usage:  
`svi.sh FILENAME`
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
