# frozen_string_literal: true
# $:.unshift File.expand_path("../lib", __FILE__)
Gem::Specification.new do |s|
  s.name        = 'linky_meter'
  s.version     = '0.1.2'
  s.date        = '2025-07-20'
  s.summary     = "retrieve eletrical consumption with linky "
  s.description = "A web crawler to linky data from your enedis account"
  s.authors     = ["miko53"]
  s.email       = 'miko53@free.fr'
  s.executables = Dir['bin/*'].map { |f| File.basename f }
  s.files       = ["lib/linky/linky_meter.rb"]
  s.homepage    = 'https://github.com/miko53/linky_meter'
  s.license     = 'GPL-3.0'
  s.add_runtime_dependency('mechanize', '~> 2.7.7', '>= 2.7.7')
#  s.add_development_dependency('byebug'', '~> 0')
  s.add_runtime_dependency('json', '~> 2.6.1', '>= 2.6.1' )
end
