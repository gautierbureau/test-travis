#!/bin/bash

export PATH=$HOME/Library/sonar/build-wrapper-linux-x86:$HOME/Library/sonar/sonar-scanner-3.3.0.1492-linux/bin:$PATH

export TRAVIS=Travis

build-wrapper-linux-x86-64 --out-dir bw-output ./build_sonar.sh
sonar-scanner
