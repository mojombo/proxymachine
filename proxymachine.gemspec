# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{proxymachine}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tom Preston-Werner"]
  s.date = %q{2009-04-27}
  s.default_executable = %q{proxymachine}
  s.email = %q{tom@mojombo.com}
  s.executables = ["proxymachine"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION.yml",
    "bin/proxymachine",
    "examples/git.rb",
    "examples/transparent.rb",
    "lib/proxymachine.rb",
    "lib/proxymachine/client_connection.rb",
    "lib/proxymachine/server_connection.rb",
    "test/proxymachine_test.rb",
    "test/test_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/mojombo/proxymachine}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{TODO}
  s.test_files = [
    "test/proxymachine_test.rb",
    "test/test_helper.rb",
    "examples/git.rb",
    "examples/transparent.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.6"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0.12.6"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.12.6"])
  end
end
