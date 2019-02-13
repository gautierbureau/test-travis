#!/bin/bash

./compile.sh clean
./compile.sh build

RC=$?

if [ $RC -ne 0 ]; then
  echo "BUILD FAILURE"
else
  echo "BUILD SUCCESS"
fi
