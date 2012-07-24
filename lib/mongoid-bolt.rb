# encoding: utf-8

##
#
module Mongoid
  class Bolt
    const_set :Version, '1.0.0'

    class << Bolt
      def version
        const_get :Version
      end

      def dependencies
        {
          'mongoid'         => [ 'mongoid'         , ' >= 3.0.1' ] ,
        }
      end

      def libdir(*args, &block)
        @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
        args.empty? ? @libdir : File.join(@libdir, *args)
      ensure
        if block
          begin
            $LOAD_PATH.unshift(@libdir)
            block.call()
          ensure
            $LOAD_PATH.shift()
          end
        end
      end

      def load(*libs)
        libs = libs.join(' ').scan(/[^\s+]+/)
        libdir{ libs.each{|lib| Kernel.load(lib) } }
      end
    end

    begin
      require 'rubygems'
    rescue LoadError
      nil
    end

    if defined?(gem)
      dependencies.each do |lib, dependency|
        gem(*dependency)
        require(lib)
      end
    end
  end
end

##
#
  module Mongoid
    class Bolt
      module Ability
        Code = proc do
        ## embedded lock class and associations
        #
          target_class = self

          class << target_class
            attr_accessor :lock_class
          end

          const_set(:Bolt, Class.new)
          lock_class = const_get(:Bolt)

          target_class.lock_class = lock_class

          lock_class.class_eval do
            define_method(:target_class){ target_class }
            define_method(:lock_class){ lock_class }

            include Mongoid::Document
            include Mongoid::Timestamps

            field(:hostname, :default => proc{ ::Mongoid::Bolt.hostname })
            field(:ppid, :default => proc{ ::Mongoid::Bolt.ppid })
            field(:pid, :default => proc{ ::Mongoid::Bolt.pid })

            attr_accessor :stolen
            alias_method :stolen?, :stolen

            def initialize(*args, &block)
              super
            ensure
              now = Time.now
              self.created_at ||= now
              self.updated_at ||= now
              @locked = false
            end

            def localhost?
              ::Mongoid::Bolt.hostname == hostname
            end

            def alive?
              return true unless localhost?
              ::Mongoid::Bolt.alive?(ppid, pid)
            end

            def relock!
              reload

              conditions = {
                '_lock._id'      => id,
                '_lock.hostname' => hostname,
                '_lock.ppid'     => ppid,
                '_lock.pid'      => pid
              }

              update = {
                '$set' => {
                  '_lock.hostname'   => ::Mongoid::Bolt.hostname,
                  '_lock.ppid'       => ::Mongoid::Bolt.ppid,
                  '_lock.pid'        => ::Mongoid::Bolt.pid,
                  '_lock.updated_at' => Time.now.utc
                }
              }

              result =
                  target_class.
                    with(safe: true).
                      where(conditions).
                        find_and_modify(update, new: false)

            ensure
              reload
            end

            def steal!
              self.stolen = !!relock!
            end

            def stale?
              localhost? and not alive?
            end

            def owner?
              ::Mongoid::Bolt.identifier == identifier
            end

            def identifier
              {:hostname => hostname, :ppid => ppid, :pid => pid}
            end
          end

          target_association_name = "_" + target_class.name.underscore.split(%r{/}).last
          
          lock_class.class_eval do
            embedded_in(target_association_name, :class_name => "::#{ target_class.name }")
          end

          embeds_one(:_lock, :class_name => "::#{ lock_class.name }")

        ## locking methods
        #
          def target_class.lock!(conditions = {}, update = {})
            conditions.to_options!
            update.to_options!

            conditions[:_lock] = nil

            update[:$set] = {:_lock => lock_class.new.attributes}

            with(safe: true).
              where(conditions).
                find_and_modify(update, new: true)
          end

          def lock!(conditions = {})
            conditions.to_options!

            begin
              if _lock and _lock.stale? and _lock.steal!
                return _lock
              end
            rescue
              nil
            end

            conditions[:_id] = id

            if self.class.lock!(conditions)
              reload

              begin
                @locked = _lock && _lock.owner?
              rescue
                nil
              end
            else
              false
            end
          end

          def unlock!
            unlocked = false

            if _lock
              begin
                _lock.destroy if _lock.owner?
                @locked = false
                unlocked = true
              rescue
                nil
              end

              reload
            end

            unlocked
          end

          def relock!
            raise(::Mongoid::Bolt::Error, "#{ name } is not locked!") unless @locked

            _lock.relock!
          end

          def locked?
            begin
              _lock and _lock.owner?
            rescue
              nil
            end
          end

          def lock(options = {}, &block)
            options.to_options!

            return block.call(_lock) if locked?

            loop do
              if lock!
                return _lock unless block

                begin
                  return block.call(_lock)
                ensure
                  unlock!
                end
              else
                if options[:blocking] == false
                  if block
                    raise(::Mongoid::Bolt::Error, name)
                  else
                    return(false)
                  end
                end

                if options[:waiting]
                  options[:waiting].call(reload._lock)
                end

                sleep(rand)
              end
            end
          end
        end

        def Ability.included(other)
          super
        ensure
          other.module_eval(&Code)
        end
      end

      def Bolt.ability
        Ability
      end

    ##
    #
      include Mongoid::Document
      include Mongoid::Timestamps

    ##
    #
      class Error < ::StandardError; end

    ##
    #
      def Bolt.for(name, options = {}, &block)
        name = name.to_s
        conditions = {:name => name}

        attributes = conditions.dup
        attributes[:created_at] || attributes[:updated_at] = Time.now.utc

        lock =
          begin
            where(conditions).first or create!(attributes)
          rescue Object => e
            sleep(rand)
            where(conditions).first or create!(attributes)
          end

        block ? lock.lock(options, &block) : lock
      end

    ##
    #
      field(:name)

      validates_presence_of(:name)
      validates_uniqueness_of(:name)

      index({:name => 1}, {:unique => true})

    ##
    #
      def Bolt.hostname
        Socket.gethostname
      end

      def Bolt.ppid
        Process.ppid
      end

      def Bolt.pid
        Process.pid
      end

      def Bolt.identifier
        {:hostname => hostname, :ppid => ppid, :pid => pid}
      end

      def Bolt.alive?(*pids)
        pids.flatten.compact.all? do |pid|
          begin
            Process.kill(0, Integer(pid))
            true
          rescue Object
            false
          end
        end
      end

    ##
    #
      include Bolt.ability
    end
  end

