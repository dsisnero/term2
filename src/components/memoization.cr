require "digest/sha256"

module Term2
  module Components
    module Memoization
      # Objects used as keys must expose a stable string hash.
      module Hashable
        abstract def hash_value : String
      end

      # Simple LRU memoization cache.
      class MemoCache(K, V)
        getter capacity : Int32

        def initialize(@capacity : Int32)
          @cache = {} of String => V
          @order = [] of String
        end

        def size : Int32
          @order.size
        end

        def get(key : K) : {V?, Bool}
          hashed = hash_key(key)
          return {nil, false} unless @cache.has_key?(hashed)

          value = @cache[hashed]?
          touch(hashed)
          {value, true}
        end

        def set(key : K, value : V)
          hashed = hash_key(key)

          if @cache.has_key?(hashed)
            @cache[hashed] = value
            touch(hashed)
            return
          end

          if @capacity > 0 && @order.size >= @capacity
            evicted = @order.shift?
            @cache.delete(evicted) if evicted
          end

          @cache[hashed] = value
          @order << hashed
        end

        private def touch(hashed : String)
          @order.delete(hashed)
          @order << hashed
        end

        private def hash_key(key : K) : String
          key.responds_to?(:hash_value) ? key.hash_value : key.hash.to_s
        end
      end

      struct HString
        include Hashable
        getter value : String

        def initialize(@value : String)
        end

        def hash_value : String
          Digest::SHA256.hexdigest(@value)
        end

        def ==(other)
          other.is_a?(HString) && other.value == @value
        end
      end

      struct HInt
        include Hashable
        getter value : Int32

        def initialize(@value : Int32)
        end

        def hash_value : String
          Digest::SHA256.hexdigest(@value.to_s)
        end

        def ==(other)
          other.is_a?(HInt) && other.value == @value
        end
      end
    end
  end
end
