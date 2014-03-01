require 'thread'

module Concurrent

  # Lazy evaluation of a block yielding an immutable result. Usefuk for expensive
  # operations that may never be needed.
  #
  # A `Delay` is similar to `Future` but solves a different problem.
  # Where a `Future` schedules an operation for immediate execution and
  # performs the operation asynchronously, a `Delay` (as the name implies)
  # delays execution of the operation until the result is actually needed.
  # 
  # When a `Delay` is created its state is set to `pending`. The value and
  # reason are both `nil`. The first time the `#value` method is called the
  # enclosed opration will be run and the calling thread will block. Other
  # threads attempting to call `#value` will block as well. Once the operation
  # is complete the *value* will be set to the result of the operation or the
  # *reason* will be set to the raised exception, as appropriate. All threads
  # blocked on `#value` will return. Subsequent calls to `#value` will immediately
  # return the cached value. The operation will only be run once. This means that
  # any side effects created by the operation will only happen once as well.
  #
  # `Delay` includes the `Concurrent::Dereferenceable` mixin to support thread
  # safety of the reference returned by `#value`.
  #
  # @see Concurrent::Dereferenceable
  #
  # @see http://clojuredocs.org/clojure_core/clojure.core/delay
  # @see http://aphyr.com/posts/306-clojure-from-the-ground-up-state
  class Delay
    include Obligation

    def initialize(opts = {}, &block)
      raise ArgumentError.new('no block given') unless block_given?

      init_obligation
      @state = :pending
      @task = block
      set_deref_options(opts)
    end

    def value
      mutex.synchronize do
        return apply_deref_options(@value) unless @state == :pending
        begin
          @value = @task.call
          @state = :fulfilled
        rescue => ex
          @reason = ex
          @state = :rejected
        ensure
          return apply_deref_options(@value)
        end
      end
    end

    def force
      self.value
      return self
    end
  end
end
