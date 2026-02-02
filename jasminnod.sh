#!/bin/bash

export LOG_PATH=$HOME/jasmin/logs
export JASMIN_RESOURCE_DIR=$HOME/jasmin-src/resource

python3 $HOME/jasmin-src/jasmind.py \
  --http-api \
  --enable-interceptor-client \
  --enable-dlr-thrower \
  --enable-dlr-lookup
