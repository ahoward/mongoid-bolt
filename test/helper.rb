# -*- encoding : utf-8 -*-

require_relative 'testing'
require_relative '../lib/mongoid-bolt.rb'

Mongoid.configure do |config|
  config.connect_to('mongoid-bolt_test')
end

require 'thread'

class Thread
  class Pipe
    class Queue < ::Queue
      attr_accessor :thread_id
    end

    def initialize
      @queues = [Queue.new, Queue.new]
    end

    def thread_id
      Thread.current.object_id
    end

    def reserve_write_queue!
      Thread.exclusive do
        @queues.each do |queue|
          next if queue.thread_id
          queue.thread_id = thread_id
          return queue
        end
      end
    end

    def write_queue
      @queues.detect{|q| q.thread_id == thread_id} || reserve_write_queue!
    end

    def read_queue
      @queues.detect{|q| q != write_queue}
    end

    def write(object)
      write_queue.push(object)
    end

    alias_method('push', 'write')

    def read
      read_queue.pop
    end

    alias_method('pop', 'read')
  end
end
