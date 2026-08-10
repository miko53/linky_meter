#!/bin/sh

find /entrypoint.d -type f -executable | sort \
| while read program
  do
  $program
  done

if [ "${#}" -eq 0 ]
then
  su ruby -s /bin/sh -c server
else
  exec "$@"
fi
