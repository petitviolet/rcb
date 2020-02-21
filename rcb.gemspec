require_relative 'lib/rcb/version'

Gem::Specification.new do |spec|
  spec.name          = "rcb"
  spec.version       = Rcb::VERSION
  spec.authors       = ["petitviolet"]
  spec.email         = ["violethero0820@gmail.com"]

  spec.summary       = %q{Ruby Circuit Breaker}
  spec.description   = %q{Ruby Circuit Breaker}
  spec.homepage      = "https://github.com/petitviolet/rcb"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/petitviolet/rcb"
  spec.metadata["changelog_uri"] = "https://github.com/petitviolet/rcb"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "byebug"
end
