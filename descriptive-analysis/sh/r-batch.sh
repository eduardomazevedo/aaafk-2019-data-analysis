#! /bin/bash

# Remove .do and attach .log
log="`basename $1`.log"

# in batch mode, nothing sent to stdout (is this guaranteed?)
# 2>&1 send stderr to stdout
./r/r-log.R $1
rc=$?

if [ -e "Rplots.pdf" ]
then
  rm Rplots.pdf
fi

if [ $rc != "0" ]
then
    echo "${magenta}Error code $rc."
    mv $log ./log/ERROR-$log
    exit $rc
else
    mv $log ./log/$log
    if [ -e ./log/ERROR-$log ]
    then
      rm ./log/ERROR-$log
    fi
    exit 0
fi
