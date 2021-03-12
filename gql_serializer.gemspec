require_relative 'lib/gql_serializer/version'

Gem::Specification.new do |spec|
  spec.name          = "gql_serializer"
  spec.version       = GqlSerializer::VERSION
  spec.authors       = ["Andrew Scullion"]
  spec.email         = ["andrewsc32@protonmail.com"]

  spec.summary       = %q{A gem that adds `as_gql` to easily serialize ActiveRecord objects}
  spec.description   = %q{A gem that adds `as_gql` to easily serialize ActiveRecord objects}
  spec.homepage      = "https://github.com/TheDro/gql_serializer"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.1")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/TheDro/gql_serializer"
  spec.metadata["changelog_uri"] = "https://github.com/TheDro/gql_serializer"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.13.1"
  spec.add_development_dependency "sqlite3", "~> 1.4.2"

  spec.add_runtime_dependency "activerecord", ">= 5.2", "<= 6.1"
end
