Gem::Specification.new do |s|
  s.name        = 'linky_meter'
  s.version     = '0.0.0'
  s.date        = '2020-08-16'
  s.summary     = "retrieve eletrical consumption with linky "
  s.description = "A web crawler to linky data from your enedis account"
  s.authors     = ["miko53"]
  s.email       = 'miko53@free.fr'
  s.files       = ["lib/linky_meter.rb"]
  s.homepage    = 'https://github.com/miko53/linky_meter'
  s.license     = 'GPL-3.0'
  s.add_runtime_dependency('mechanize', '~> 2.7.6', '>= 2.7.6')
#  s.add_runtime_dependency('byebug'', '~> 0')
  s.add_runtime_dependency('json', '~> 2.3.0', '>= 2.3.0' )
end