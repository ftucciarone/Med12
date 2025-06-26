#!/bin/bash
# Check operating system 
# (shamelessly copied from https://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script )

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # linux-type system
    datecommand=date
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    datecommand=gdate
elif [[ "$OSTYPE" == "cygwin" ]]; then
    # POSIX compatibility layer and Linux environment emulation for Windows
    datecommand=date
elif [[ "$OSTYPE" == "msys" ]]; then
    # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
    datecommand=date
elif [[ "$OSTYPE" == "win32" ]]; then
    # I'm not sure this can happen.
    datecommand=
elif [[ "$OSTYPE" == "freebsd"* ]]; then
    # FreeBSD
    datecommand=date
else
    echo " Operating system not recognized"
    exit -2
fi

function dateDiffMonth() {
    local y1=$($datecommand -d "$1" '+%Y') # extract the year from your date1
    local y2=$($datecommand -d "$2" '+%Y') # extract the year from your date2
    local m1=$($datecommand -d "$1" '+%m') # extract the month from your date1
    local m2=$($datecommand -d "$2" '+%m') # extract the month from your date2
    # compute the months difference 12*year diff+ months diff 
    # 10# force the shell to interpret the following number in base-10
    echo $(( ($y2 - $y1) * 12 + (10#$m2 - 10#$m1) )) 
}

function getDay() {
    echo $($datecommand -d $currentDate +%d)
}

function getMonth() {
    echo $($datecommand -d $currentDate +%m)
}

function getYear() {
    echo $($datecommand -d $currentDate +%Y)
}

function echoDay() {
    echo "Processing" $($datecommand -d $currentDate +%d) `LC_NAME=en_US $datecommand -d $currentDate '+%B'` $($datecommand -d $currentDate +%Y)
}

function echoMonth() {
    echo "Processing" `LC_NAME=en_US $datecommand -d $currentDate '+%B'` $($datecommand -d $currentDate +%Y)
}
