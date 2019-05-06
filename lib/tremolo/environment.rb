module Tremolo
  class Environment
    def initialize(parent = nil)
      @parent = parent
      @data = {}
    end

    def spawn
      self.class.new(self)
    end

    def key?(key)
      !!lookup(key)
    end

    def []=(key, value)
      env = lookup(key)
      if env
        env.set(key, value)
      else
        set(key, value)
      end
    end

    def [](key)
      env = lookup(key)
      env ? env.get(key) : nil
    end

    protected

    def get(key)
      @data[key]
    end

    def set(key, value)
      @data[key] = value
    end

    def lookup(key)
      if @data.key?(key)
        self
      elsif @parent
        @parent.lookup(key)
      else
        nil
      end
    end
  end
end
