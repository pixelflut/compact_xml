# -*- encoding: utf-8 -*-
require File.expand_path('../lib/compact_xml/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["pixelflut GmbH"]
  gem.email         = ["info@pixelflut.net"]
  gem.description   = "Adds and CompactXml converter to Array and Hash. If included into an Rails aplication, it also adds a CompactXML renderer."
  gem.summary       = gem.description
  gem.homepage      = "http://github.com/pixelflut/compact_xml"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "compact_xml"
  gem.require_paths = ["lib"]
  gem.version       = CompactXml::VERSION

end
