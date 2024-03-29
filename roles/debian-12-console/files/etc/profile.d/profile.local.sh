#!/bin/bash
set +o history

rm ~/*.tmp >/dev/null 2>&1
rm ~/.local/share/recently-used.xbel >/dev/null 2>&1
umask 077
if groups $USER | grep -q '\busers\b'; then
    echo "History kept"
    # ignore duplicate commands, ignore commands starting with a space
    export HISTCONTROL=erasedups:ignorespace:ignorespace
    export HISTSIZE=400
    export HISTFILESIZE=400
else
    rm ~/.bash_history >/dev/null 2>&1
fi

set -o history
