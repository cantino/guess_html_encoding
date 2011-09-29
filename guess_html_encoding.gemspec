# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "guess_html_encoding/version"

Gem::Specification.new do |s|
  s.name        = "guess_html_encoding"
  s.version     = GuessHtmlEncoding::VERSION
  s.authors     = ["Andrew Cantino (Iteration Labs, LLC)"]
  s.email       = ["andrew@iterationlabs.com"]
  s.homepage    = "http://github.com/iterationlabs/guess_html_encoding"
  s.summary     = %q{This gem helps guess the encoding of an HTML page.}
  s.description = %q{This gem helps guess the encoding of an HTML page.}

  s.rubyforge_project = "guess_html_encoding"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
