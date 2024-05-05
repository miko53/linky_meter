#!/bin/sh

echo -e 'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n'

parser
#| tail -c+2  | head -c-2
