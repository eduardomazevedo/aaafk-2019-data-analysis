#! /bin/bash

# Remove .do and attach .log
log="`basename "$1" .do`"
log="$log.log"

# in batch mode, nothing sent to stdout (is this guaranteed?)
# 2>&1 send stderr to stdout
stderr=`stata-mp -b do $1 2>&1`
rc=$?
if [ -n "$stderr" ]  # typically usage info.   -n is "not empty"
then
    echo "${magenta}Stata itself sent the following to stderr:"
    echo "${magenta}$stderr"
    mv $log ./log/ERROR-$1
    exit $rc
elif [ $rc != "0" ]
then
    echo "${magenta}Stata itself threw an error (code $rc)."
    mv $log ./log/ERROR-$log
    exit $rc
elif egrep -nH --before-context=2 --max-count=1 --color "^r\([0-9]+\);$" "$log"
then
    # use --max-count to avoid matching final line ("end of do-file") when
    # do-file terminates with error
    # before-context: number of lines before match to return
    # max-count: stops after a certain number of matches
    # + is one or more in regex
    echo "Preceding error caused by $1."
    mv $log ./log/ERROR-$log
    exit 1
else
    mv $log ./log/$log
    if [ -e ./log/ERROR-$log ]
    then
      rm ./log/ERROR-$log
    fi
    exit 0
fi