#! /bin/bash

# Attach .log to filename
log="`basename $1`.log"
pyscript=$1
shift
# Send stdout and stderr to the log file
python $pyscript $@ > $log 2>&1
rc=$?

if [ $rc != "0" ]
then
    echo "${magenta}Error code $rc."
    mv $log ./log/ERROR-$log
    if [ -e ./log/$log ]
    then
      rm ./log/$log
    fi
    exit $rc
else
    mv $log ./log/$log
    if [ -e ./log/ERROR-$log ]
    then
      rm ./log/ERROR-$log
    fi
    exit $rc
fi
