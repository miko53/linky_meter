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
require_relative 'linky_meter'

username = ENV['LINKY_USERNAME']
password = ENV['LINKY_PASSWORD']

linky = LinkyMeter.new
linky.connect(username, password)

result = linky.get(DateTime.new(2020, 02, 13), DateTime.new(2020, 03, 13), LinkyMeter::BY_DAY)
p result
