#!/bin/sh

while true
do
  nc -lvp ${PORT:-80} -e parser-http
done
