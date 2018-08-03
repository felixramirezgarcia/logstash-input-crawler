Gem::Specification.new do |s|
  s.name          = 'logstash-input-crawler'
  s.version       = '1.0.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'This plugin get the links and the html content from a initial page .'
  s.description   = 'This plugin need set the initial url.'
  s.homepage      = 'https://github.com/felixramirezgarcia/logstash-input-crawler'
  s.authors       = ['Felix R G']
  s.email         = 'felixramirezgarcia@correo.ugr.es'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core"
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'stud', '>= 0.0.22'
  s.add_development_dependency 'logstash-devutils', '>= 0.0.16'
  s.add_runtime_dependency "mechanize"
  s.add_runtime_dependency "nokogiri"
end
