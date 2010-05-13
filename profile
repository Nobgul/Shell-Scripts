# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))
# and Bourne compatible shells (bash(1), ksh(1), ash(1), ...).

BLOCKSIZE=K; export BLOCKSIZE

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/bin:/usr/X11R6/bin:$HOME/bin; export PATH

export HISTFILESIZE="2000"
export HISTCONTROL="ignoreboth"
export HISTCONTROL="ignoredups"
readonly HISTFILE
readonly HISTFILESIZE
readonly HISTSIZE

TERM=xterm-color
export TERM
shopt -s checkwinsize

if [ "`id -u`" -eq 0 ]; then
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
else
  PATH="/usr/local/bin:/usr/bin:/bin:/usr/games"
fi

case "$TERM" in
xterm*|rxvt*)
        PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
        ;;
*)
        ;;
esac

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

PS1='\[\033[1;34m\][\[\033[1;37m\]\T\[\033[1;34m\]]\[\033[1;34m\][\[\033[1;37m\]\d\[\033[1;34m\]][\[\033[1;37m\]\u\[\033[1;34m\]@\[\033[1;37m\]\H\[\033[1;34m\]]\n[\[\033[1;37m\]\w\[\033[1;34m\]] > \[\033[1;0m\]'

export PS1
export PS2='$PS1'
export EDITOR="/usr/bin/nano"


export PATH

umask 022

alias ls='ls -a --color'
alias lss='ls -shaxSr'          # sort by size
alias lsd='ls -latr'            # sort by date

# on this day
alias today='grep -h -d skip `date +%m/%d` /usr/share/calendar/*'

extract () {
     if [ -f $1 ] ; then
         case $1 in
             *.tar.bz2)   tar xjf $1        ;;
             *.tar.gz)    tar xzf $1     ;;
             *.bz2)       bunzip2 $1       ;;
             *.rar)       rar x $1     ;;
             *.gz)        gunzip $1     ;;
             *.tar)       tar xf $1        ;;
             *.tbz2)      tar xjf $1      ;;
             *.tgz)       tar xzf $1       ;;
             *.zip)       unzip $1     ;;
             *.Z)         uncompress $1  ;;
             *.7z)        7z x $1    ;;
             *)           echo "'$1' cannot be extracted via extract()" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}


psgrep() {
        if [ ! -z $1 ] ; then
                echo "Grepping for processes matching $1..."
                ps aux | grep $1 | grep -v grep
        else
                echo "!! Need name to grep for"
        fi
}


