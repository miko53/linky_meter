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
require_relative 'lib/linky_meter'
# require 'byebug'

username = ENV['LINKY_USERNAME']
password = ENV['LINKY_PASSWORD']
authentication_cookie = ENV['LINKY_COOKIE_INTERNAL_AUTH_ID']

linky = LinkyMeter.new(true)
linky.connect(username, password, authentication_cookie)

#result = linky.get(DateTime.new(2028, 03, 01), DateTime.new(2020, 03, 01), LinkyMeter::BY_YEAR)
#p result

#result = linky.get(DateTime.new(2020, 01, 01), DateTime.new(2020, 03, 01), LinkyMeter::BY_MONTH)
#p result

result = linky.get(DateTime.new(2024, 04, 15), DateTime.new(2024, 04, 17), LinkyMeter::BY_DAY)
p result

#result = linky.get(DateTime.new(2024, 04, 15), DateTime.new(2024, 04, 15), LinkyMeter::BY_HOUR)
#p result
