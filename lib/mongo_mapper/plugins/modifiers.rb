# encoding: UTF-8
module MongoMapper
  module Plugins
    module Modifiers
      extend ActiveSupport::Concern

      module ClassMethods
        def increment(*args)
          modifier_update('$inc', args)
        end

        def decrement(*args)
          criteria, keys = criteria_and_keys_from_args(args)
          values, to_decrement = keys.values, {}
          keys.keys.each_with_index { |k, i| to_decrement[k] = -values[i].abs }
          collection.update(criteria, {'$inc' => to_decrement}, :multi => true)
        end

        def set(*args)
          criteria, updates = criteria_and_keys_from_args(args)
          updates.each do |key, value|
            updates[key] = keys[key.to_s].set(value) if key?(key)
          end
          collection.update(criteria, {'$set' => updates}, :multi => true)
        end

        def unset(*args)
          if args[0].is_a?(Hash)
            criteria, keys = args.shift, args
          else
            keys, ids = args.partition { |arg| arg.is_a?(Symbol) }
            criteria = {:id => ids}
          end

          criteria  = criteria_hash(criteria).to_hash
          modifiers = keys.inject({}) { |hash, key| hash[key] = 1; hash }
          collection.update(criteria, {'$unset' => modifiers}, :multi => true)
        end

        def push(*args)
          modifier_update('$push', args)
        end

        def push_all(*args)
          modifier_update('$pushAll', args)
        end

        def add_to_set(*args)
          modifier_update('$addToSet', args)
        end
        alias push_uniq add_to_set

        def pull(*args)
          modifier_update('$pull', args)
        end

        def pull_all(*args)
          modifier_update('$pullAll', args)
        end

        def pop(*args)
          modifier_update('$pop', args)
        end

        private
          def modifier_update(modifier, args)
            criteria, updates, options = criteria_and_keys_from_args(args)
            if options
              collection.update(criteria, {modifier => updates}, options.merge(:multi => true))
            else
              collection.update(criteria, {modifier => updates}, :multi => true)
            end    
          end

          def criteria_and_keys_from_args(args)
            popped_args = args.pop
            if popped_args.nil? || (popped_args[:upsert].nil? && popped_args[:safe].nil?)
              options = nil
              keys = popped_args.nil? ? args.pop : popped_args
            else
              options = { :upsert => popped_args[:upsert], :safe => popped_args[:safe] }.reject{|k,v| v.nil?}
              keys = args.pop
            end
            
            criteria = args[0].is_a?(Hash) ? args[0] : {:id => args}
            [criteria_hash(criteria).to_hash, keys, options]
          end
      end

      def unset(*keys)
        self.class.unset(id, *keys)
      end

      def increment(hash, options=nil)
        self.class.increment(id, hash, options)
      end

      def decrement(hash, options=nil)
        self.class.decrement(id, hash, options)
      end

      def set(hash, options=nil)
        self.class.set(id, hash, options)
      end

      def push(hash, options=nil)
        self.class.push(id, hash, options)
      end

      def push_all(hash, options=nil)
        self.class.push_all(id, hash, options)
      end

      def pull(hash, options=nil)
        self.class.pull(id, hash, options)
      end

      def pull_all(hash, options=nil)
        self.class.pull_all(id, hash, options)
      end

      def add_to_set(hash, options=nil)
        self.class.push_uniq(id, hash, options)
      end
      alias push_uniq add_to_set

      def pop(hash, options=nil)
        self.class.pop(id, hash, options)
      end
    end
  end
end