## mongoid-bolt.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "mongoid-bolt"
  spec.version = "1.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "mongoid-bolt"
  spec.description = "a mongoid 3/moped compatible lock implementation and mixin"

  spec.files =
["README.md",
 "Rakefile",
 "lib",
 "lib/mongoid-bolt.rb",
 "mongoid-bolt.gemspec",
 "test",
 "test/helper.rb",
 "test/mongoid-bolt_test.rb",
 "test/testing.rb"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["mongoid", " >= 3.0.1"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/mongoid-bolt"
end
