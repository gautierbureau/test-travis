#!/bin/bash

if [ -z "$1" ]; then
  echo "You need to give build or clean as argument."
  exit 1
fi

if [ "$1" = "build" ]; then
  g++ -c -g -O0 foo.cpp -o foo.o
  g++ -c -g -O0 main.cpp -o main.o
  g++ foo.o main.o -o main
  # ./main
elif [ "$1" = "build-tests" ]; then
  # Warning I compiled with   g++ -c -g -O0 -fprofile-arcs -ftest-coverage --coverage foo.cpp -o foo.o but
  # after I had trouble with gcov that was not able to generate the full path of the file, and then putting them in a different
  # folder caused problems to find files correctly, in gcno file name was just File 'foo.cpp' and not File '/home/bureaugau/Codes/test-travis/foo.cpp'
  # Forcing to use full path saved the problem, in cmake I belive we don't have the problem
  g++ -c -g -O0 --coverage $(realpath foo.cpp) -o $(basename $(realpath foo.cpp) .cpp).o
  g++ -c -g -O0 $(realpath main.cpp) -o $(basename $(realpath main.cpp) .cpp).o
  g++ foo.o main.o --coverage -o main

  g++ -c -g -O0 --coverage $(realpath test.cpp) -o $(basename $(realpath test.cpp) .cpp).o
  g++ -g -O0 --coverage $(realpath test.o) $(realpath foo.o) -o $PWD/unittest -lgtest -lgtest_main
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
  cd coverage
  for file in $(find .. -name "*.gcno"); do
    cpp_file_name=$(basename $file .gcno)
    cpp_file=$(find .. -name "$cpp_file_name.cpp") # In Cmake cpp is not need as it generates .cpp.gcno files
    gcov -pb $(realpath $cpp_file) -o $(realpath $file)
  done
  rm -f \#usr\#*
  rm -f $(find . -name "*test.cpp.gcov")
  cd ..
  # Comment because of cxx plugin not working on sonarcloud (report.xml wanted by this plugin)
  # L'autre est un test sur gcovr pour se servir des fichiers gcov que j'ai créée au dessus, ce qui diffère du premier appel gcov ou les .gcov ne sont encore créés
  # mkdir -p coverage/gcovr-report
  # if [ -z "$TRAVIS" ]; then
  #   gcovr $PWD --root $PWD --html --html-details --use-gcov-files --object-directory coverage --output coverage/gcovr-report/index.html --keep --filter=.*foo.*
  # fi
  # if [ ! -z "$TRAVIS" ]; then
  #   GCOVR_OPTION=""
  # else
  #   GCOVR_OPTION="--use-gcov-files"
  # fi
  #gcovr -r $PWD --xml --keep $GCOVR_OPTION --object-directory=$PWD/coverage --filter=.*foo.* > coverage/report.xml
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
