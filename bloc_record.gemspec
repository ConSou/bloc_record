Gem::Specification.new do |s|
  s.name = 'bloc_record'
  s.version = '0.0.0'
  s.date = '2018-12-03'
  s.summary = 'BlocRecord ORM'
  s.description = 'An Active Record like ORM adaptor'
  s.authors = ['Conor Souhrada']
  s.email = 'conorsouhrada@gmail.com'
  s.files = Dir['lib/**/*.rb']
  s.require_paths = ["lib"]
  s.homepage = 'http://rubygems.org/gems/bloc_record'
  s.license = 'MIT'
  s.add_runtime_dependency 'sqlite3'
end
