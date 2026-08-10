#!/bin/sh

if [ ! -z "${LINKY_USERNAME_FILE}" ]
then
  _U="$(cat "${LINKY_USERNAME_FILE}")"
fi

if [ ! -z "${LINKY_PASSWORD_FILE}" ]
then
  _P="$(cat "${LINKY_PASSWORD_FILE}")"
fi

if [ ! -z "${LINKY_COOKIE_INTERNAL_AUTH_ID_FILE}" ]
then
  _C="$(cat "${LINKY_COOKIE_INTERNAL_AUTH_ID_FILE}")"
fi

LINKY_USERNAME="${_U:-LINKY_USERNAME}" \
LINKY_PASSWORD="${_P:-LINKY_PASSWORD}" \
LINKY_COOKIE_INTERNAL_AUTH_ID="${_C:-LINKY_COOKIE_INTERNAL_AUTH_ID}" \
ruby /home/ruby/app/linky_get_data_day.rb
