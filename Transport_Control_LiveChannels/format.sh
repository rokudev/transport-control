#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: format.sh <url>"
    exit 0
fi

if [ ! -f /usr/local/bin/youtube-dl ]; then
    sudo curl -L "https://yt-dl.org/downloads/latest/youtube-dl" -o /usr/local/bin/youtube-dl
    sudo chmod a+rx /usr/local/bin/youtube-dl
fi

youtube-dl --list-formats $1

read -p "Enter format code: " fcode

youtube-dl -f $fcode -g $1
