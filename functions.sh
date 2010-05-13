#!/usr/local/bin/bash
function reverse() {
        string=$1
        len=$(echo -n $string | wc -c)
        while test $len -gt 0
        do
                rev=$rev$(echo $string | cut -c $len)
                len=$(( len - 1 ))
        done
        echo $rev
}

ANIM="/-\\|"
PAD="           "
SLEEP="0.1"

ANIM_L="$(reverse $ANIM)"
PAD_LN=${#PAD}
ANIM_LN=${#ANIM}
u=0; re=0; l=0

function wait() {
PROCESS=$1
while ( ps ax | grep $PROCESS | grep -v "grep" 1>/dev/null ); do
        if [ $re -eq 1 ]; then L=$ANIM_L; else L=$ANIM; fi
        if [ $re -eq 1 ]; then p=$(( $PAD_LN - $u )); else p=$u; fi
        echo -ne "${PAD:0:$p} ${L:$l:1} ${PAD:$p:$PAD_LN} \r"
        if [ $u -eq $PAD_LN ]; then u=0; if [ $re -eq 1 ]; then re=0; else re=1; fi; fi
        u=$(( u + 1 )); l=$(( l + 1 ))
        if [ $l -eq $ANIM_LN ]; then l=0; fi
        sleep $SLEEP
done
}

