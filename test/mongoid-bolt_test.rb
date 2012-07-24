require_relative 'helper'

Testing Mongoid::Bolt do
##
#
  Bolt = Mongoid::Bolt

  class A
    include Mongoid::Document
    include Bolt::Ability
  end
        
  setup do
    Bolt.destroy_all
    A.destroy_all
  end

  test 'that locks can be acquired by name' do
    lock = assert{ Bolt.for(:shared_resource) } 
  end

  test 'that locks can be locked' do
    lock = assert{ Bolt.for(:shared_resource) } 
    assert{ lock.lock! } 
  end

  test 'that locks cannot be locked twice' do
    lock = assert{ Bolt.for(:shared_resource) } 
    assert{ lock.lock! } 
    assert{ !lock.lock! } 
  end

  test 'that locks can be re-locked' do
    lock = assert{ Bolt.for(:shared_resource) } 
    assert{ lock.lock! } 
    a = lock._lock.updated_at
    sleep(0.042)
    assert{ lock.relock! } 
    b = lock._lock.updated_at
    assert{ b > a }
  end

  test 'that locks can be un-locked' do
    lock = assert{ Bolt.for(:shared_resource) } 
    assert{ lock.lock! } 
    assert{ lock.unlock! } 
  end

  test 'that locks know when they are locked' do
    lock = assert{ Bolt.for(:shared_resource) } 
    assert{ !lock.locked? }
    assert{ lock.lock! }
    assert{ lock.locked? }
  end

  test 'that #lock takes a block' do
    lock = assert{ Bolt.for(:shared_resource) } 
    assert do
      assert{ !lock.locked? }
      lock.lock{ assert{ lock.locked? } }
      assert{ !lock.locked? }
    end
  end

  test 'that other classes can mix-in lockability' do
    locked = false
    assert{ A.create.lock{ locked = true } }
    assert{ locked }
  end
end
