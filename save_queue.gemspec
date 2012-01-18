# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "save_queue/version"

Gem::Specification.new do |s|
  s.name        = "save_queue"
  s.version     = SaveQueue::VERSION
  s.authors     = ["Alexander Paramonov"]
  s.email       = ["alexander.n.paramonov@gmail.com"]
  s.homepage    = "http://github.com/AlexParamonov/save_queue"
  s.summary     = %q{Push related objects to a queue for delayed save}
  s.description = %q{Save Queue allows to push objects to other object's queue for delayed save.
Queue save will triggered on object#save.}

  s.rubyforge_project = "save_queue"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec", ">= 2.6"
  s.add_development_dependency "rake"
  s.add_runtime_dependency "hooks"
end
