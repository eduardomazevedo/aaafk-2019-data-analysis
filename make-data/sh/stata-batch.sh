#! /bin/bash

# Stata's log name
slog="`basename $1 .do`.log"
# Log name with an extra .do 
log="`basename $1`.log"
stscript=$1
shift

# in batch mode, nothing sent to stdout (is this guaranteed?)
# 2>&1 send stderr to stdout
stderr=`stata-mp -b do $stscript $@ 2>&1`
rc=$?
if [ -n "$stderr" ]  # typically usage info.   -n is "not empty"
then
    echo "${magenta}Stata itself sent the following to stderr:"
    echo "${magenta}$stderr"
    mv $slog ./log/ERROR-$log
    if [ -e ./log/$log ]
    then
      rm ./log/$log
    fi
    exit $rc
elif [ $rc != "0" ]
then
    echo "${magenta}Stata itself threw an error (code $rc)."
    mv $slog ./log/ERROR-$log
    if [ -e ./log/$log ]
    then
      rm ./log/$log
    fi
    exit $rc
elif egrep -nH --before-context=2 --max-count=1 --color "^r\([0-9]+\);$" "$slog"
then
    # use --max-count to avoid matching final line ("end of do-file") when
    # do-file terminates with error
    # before-context: number of lines before match to return
    # max-count: stops after a certain number of matches
    # + is one or more in regex
    echo "Preceding error caused by $1."
    mv $slog ./log/ERROR-$log
    if [ -e ./log/$log ]
    then
      rm ./log/$log
    fi
    exit 1
else
    mv $slog ./log/$log
    if [ -e ./log/ERROR-$log ]
    then
      rm ./log/ERROR-$log
    fi
    exit 0
fi