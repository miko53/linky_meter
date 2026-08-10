# Copyright (c) 2020 miko53
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

#load 'linky_meter.rb'
require_relative 'lib/linky/linky_meter'
# require 'byebug'

username = ENV['LINKY_USERNAME']
password = ENV['LINKY_PASSWORD']
authentication_cookie = ENV['LINKY_COOKIE_INTERNAL_AUTH_ID']
# dateFrom = ENV['DATE_FROM']
# dateTo = ENV['DATE_TO']
LOG = (ENV['DEBUG'] === 'true')

linky = Linky::LinkyMeter.new(LOG)
linky.connect(username, password, authentication_cookie)

result = linky.get(DateTime.new(2024, 04, 15), DateTime.new(2024, 04, 17), Linky::LinkyMeter::BY_DAY)

# Not need to pass date to linky_meter because enedis will give every date what they have in stock (~3y)
#result = linky.get(DateTime.iso8601(dateFrom), DateTime.iso8601(dateTo), Linky::LinkyMeter::BY_DAY)

puts JSON.generate(result)
