# -*- encoding : utf-8 -*-
require_relative 'testing'
require_relative '../lib/mongoid-bolt.rb'

Mongoid.configure do |config|
  config.connect_to('mongoid-bolt_test')
end
