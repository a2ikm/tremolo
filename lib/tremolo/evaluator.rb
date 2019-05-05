module Tremolo
  class Environment
    def initialize(parent = nil)
      @parent = parent
      @data = {}
    end

    def spawn
      self.class.new(self)
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

  class Function
    attr_reader :node, :env

    def initialize(node, env)
      @node = node
      @env = env
    end
  end

  class Evaluator
    def initialize(program)
      @program = program
      @top_level = Environment.new
    end

    def start
      evaluate(@program, @top_level)
    end

    def evaluate(node, env)
      case node.type
      when :binary
        evaluate_binary(node, env)
      when :number
        evaluate_number(node, env)
      when :program
        evaluate_program(node, env)
      when :block
        evaluate_block(node, env)
      when :assign
        evaluate_assign(node, env)
      when :ident
        evaluate_ident(node, env)
      when :if
        evaluate_if(node, env)
      when :func
        evaluate_func(node, env)
      when :call
        evaluate_call(node, env)
      end
    end

    BINARY_OPERATORS = {
      eq:   lambda { |l, r| l == r },
      ne:   lambda { |l, r| l != r },
      lt:   lambda { |l, r| l <  r },
      lteq: lambda { |l, r| l <= r },
      gt:   lambda { |l, r| l >  r },
      gteq: lambda { |l, r| l >= r },
      add:  lambda { |l, r| l +  r },
      sub:  lambda { |l, r| l -  r },
      mul:  lambda { |l, r| l *  r },
      div:  lambda { |l, r| l /  r },
      mod:  lambda { |l, r| l %  r },
    }

    def evaluate_binary(node, env)
      op = BINARY_OPERATORS[node.op]
      op.call(
        evaluate(node.lhs, env),
        evaluate(node.rhs, env),
      )
    end

    def evaluate_number(node, env)
      node.lhs.to_i
    end

    def evaluate_program(node, env)
      evaluate_stmts(node.stmts, env)
    end

    def evaluate_block(node, env)
      evaluate_stmts(node.stmts, env.spawn)
    end

    def evaluate_stmts(stmts, env)
      last = nil
      stmts.each do |stmt|
        last = evaluate(stmt, env)
      end
      last
    end

    def evaluate_assign(node, env)
      env[node.lhs] = evaluate(node.rhs, env)
    end

    def evaluate_ident(node, env)
      env[node.lhs]
    end

    def evaluate_if(node, env)
      if evaluate(node.cond, env)
        evaluate(node.lhs, env.spawn)
      elsif node.rhs
        evaluate(node.rhs, env.spawn)
      end
    end

    def evaluate_func(node, env)
      Function.new(node, env)
    end

    def evaluate_call(node, env)
      func = env[node.lhs]
      abort "func `#{node.lhs}` is not defined" if func.nil?

      new_env = func.env.spawn
      func.node.params.zip(node.args).each do |param, arg|
        new_env[param.lhs] = arg.lhs
      end
      evaluate(func.node.body, new_env)
    end
  end
end
