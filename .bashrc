# ~/.bashrc: executed by bash(1) for non-login shells.

umask 022

set_prompt_style () {
  local USER_COLOR="\[\033[1;34m\]"  #Light Blue
  local DIR_COLOR="\[\033[1:36m\]"   #Light Grey
  local RESET_COLOR="\[\033[1;37m\]" #White
  local SYMBOL="$"

  if [ `whoami` == "root" ] ; then
    USER_COLOR="\[\033[0;31m\]"       #Light Red
    DIR_COLOR=$USER_COLOR
    SYMBOL="#"
  fi

PS1='\[\033[1;34m\][\[\033[1;37m\]\T\[\033[1;34m\]]\[\033[1;34m\][\[\033[1;37m\]\d\[\033[1;34m\]][\[\033[1;37m\]\u\[\033[1;34m\]@\[\033[1;37m\]\H\[\033[1;34m\]]\n[\[\033[1;37m\]\w\[\033[1;34m\]] > \[\033[1;0m\]'
}
set_prompt_style


dirsize ()
{
du -shx * .[a-zA-Z0-9_]* 2> /dev/null | \
egrep '^ *[0-9.]*[MG]' | sort -n > /tmp/list
egrep '^ *[0-9.]*M' /tmp/list
egrep '^ *[0-9.]*G' /tmp/list
rm /tmp/list
}

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

export PATH="/usr/local/lib/cw:$PATH"

