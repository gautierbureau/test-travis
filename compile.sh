#!/bin/bash

if [ -z "$1" ]; then
  echo "You need to give build or clean as argument."
  exit 1
fi

if [ "$1" = "build" ]; then
  g++ -c -g -O0 foo.cpp -o foo.o
  g++ -c -g -O0 main.cpp -o main.o
  g++ foo.o main.o -o main
  ./main
elif [ "$1" = "build-tests" ]; then
  g++ -c -g -O0 --coverage foo.cpp -o foo.o
  g++ -c -g -O0 main.cpp -o main.o
  g++ foo.o main.o --coverage -o main

  g++ -c -g -O0 --coverage test.cpp -o test.o
  g++ -g -O0 --coverage test.o foo.o -o unittest -lgtest -lgtest_main
  ./unittest

  # Lcov
  if [ -z "$TRAVIS" ]; then
    lcov --directory . --capture --output-file coverage.info.unittest
    lcov --extract coverage.info.unittest '*test-travis/foo*' --output-file coverage.info.unittest.filtered
    lcov --remove coverage.info.unittest '/usr*' '*test-travis/test*' --output-file coverage.info.unittest.filtered
    cat coverage.info.unittest.filtered >> coverage.info
    mkdir -p report-lcov
    genhtml --no-function-coverage -o report-lcov coverage.info
  fi

  # Gcovr
  if [ -z "$TRAVIS" ]; then
    mkdir -p report-gcovr/gcov
    gcovr $PWD --root $PWD --html --html-details --output report-gcovr/index.html --keep --filter=.*foo.*
    mv *.gcov report-gcovr/gcov
  fi

  # My way
  mkdir -p coverage
  for file in $(find . -name "*.gcno"); do
    cpp_file_name=$(basename $file .gcno)
    cpp_file=$(find . -name "$cpp_file_name.cpp") # In Cmake cpp is not need as it generates .cpp.gcno files
    gcov -pb $cpp_file -o $file
  done
  rm -f \#usr\#*
  mv *.gcov coverage
  rm -f coverage/test*
  mkdir -p coverage/gcovr-report
  if [ -z "$TRAVIS" ]; then
    gcovr $PWD --root $PWD --html --html-details --use-gcov-files --object-directory coverage --output coverage/gcovr-report/index.html --keep --filter=.*foo.*
  fi
  if [ ! -z "$TRAVIS" ]; then
    GCOVR_OPTION=""
  else
    GCOVR_OPTION="--use-gcov-files"
  fi
  gcovr -r $PWD --xml --keep $GCOVR_OPTION --object-directory=$PWD/coverage --filter=.*foo.* > coverage/report.xml
elif [ "$1" = "clean" ]; then
  rm -f *.o
  rm -f *.gcno
  rm -f *.gcda
  rm -rf report-lcov
  rm -rf report-gcovr
  rm -rf coverage
  rm -f coverage.info*
  rm -f *.gcov
  if [ -f "main" ]; then rm main; fi
  if [ -f "unittest" ]; then rm unittest; fi
else
  echo "Nothing."
fi

# When compiling --coverage implies -fprofile-arcs -ftest-coverage
# When linking --coverage implies -lgcov
