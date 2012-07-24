NAME
----
  mongoid-bolt

INSTALL
-------
  gem install mongoid-bolt

SYNOPSIS
--------

````ruby

  require 'mongoid-bolt'

  Bolt.for(:shared_resource) do
    ioslated!
  end


  class A
    include Mongoid::Document
    include Mongoid::Bolt
  end

  a = A.new

  a.lock!

  a.unlock!

  a.lock do
    isolated!
  end



````

DESCRIPTION
-----------

mongoid-bolt is a concrete lock implementation and mixin.

it is process safe and atomic in a mongoid cluster.
