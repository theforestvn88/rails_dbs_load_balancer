# frozen_string_literal: true

require_relative "lib/rails_dbs_load_balancer/version"

Gem::Specification.new do |spec|
  spec.name = "rails_dbs_load_balancer"
  spec.version = RailsDbsLoadBalancer::VERSION
  spec.authors = ["theforestvn88"]
  spec.email = ["theforestvn88@gmail.com"]

  spec.summary = "rails multiple databases load balancer"
  spec.description = "rails multiple databases load balancer"
  spec.homepage = "https://github.com/theforestvn88/rails_dbs_load_balancer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://github.com/theforestvn88/rails_dbs_load_balancer"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/theforestvn88/rails_dbs_load_balancer"
  spec.metadata["changelog_uri"] = "https://github.com/theforestvn88/rails_dbs_load_balancer"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
