#!/bin/bash
tab="    "
# Check operating system 
function checkExistence() {
  if [ ! -d "$1" ]; then
    echo "                   ERROR STOP: $2"; echo " "; exit -1
  fi
}