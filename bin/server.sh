#!/bin/sh

# https://dev.to/leandronsp/building-a-web-server-in-bash-part-ii-parsing-http-14kg

if [ "${DEBUG}" = "true" ]
then
  printf "Server launched with : "
  id
fi

rm -f /home/ruby/response
mkfifo /home/ruby/response

function handleRequest() {
  while read line; do
#    echo $line
    trline=`echo ${line} | tr -d '[\r\n]'`

    if [ -z "${trline}" ]; then
      break
    fi

    HEADLINE_REGEX='(.*?)\s(.*?)\sHTTP.*?'
    [[ "${trline}" =~ ${HEADLINE_REGEX} ]] &&
      REQUEST=$(echo $trline | sed -E "s/${HEADLINE_REGEX}/\1 \2/")

    DATE_FROM_REGEX='date-from:\s(.*?)'
    [[ "$trline" =~ $DATE_FROM_REGEX ]] &&
      DATE_FROM=$(echo $trline | sed -E "s/$DATE_FROM_REGEX/\1/")

    DATE_TO_REGEX='date-to:\s(.*?)'
    [[ "$trline" =~ $DATE_TO_REGEX ]] &&
      DATE_TO=$(echo $trline | sed -E "s/$DATE_TO_REGEX/\1/")
  done

  case "${REQUEST}" in
    "GET /")
      RESPONSE="HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n$(parser)"
      ;;
    "GET /p")
      RESPONSE="HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n$(parserPower "${DATE_FROM}" "${DATE_TO}")"
      ;;
    *)
      RESPONSE="HTTP/1.1 404 NotFound\r\n\r\n\r\nNot Found\r\n\r\n"
      ;;
  esac

  echo -e "${RESPONSE}" > /home/ruby/response
}

while true
do
  cat /home/ruby/response | nc -lvp ${PORT:-80} | handleRequest
done
