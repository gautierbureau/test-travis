#!/bin/bash

./compile.sh clean
./compile.sh build-tests

RC=$?

if [ $RC -ne 0 ]; then
  echo "BUILD FAILURE"
else
  echo "BUILD SUCCESS"
fi
