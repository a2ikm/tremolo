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

  class Function
    attr_reader :node, :env

    def initialize(node, env)
      @node = node
      @env = env
    end
  end

  class Evaluator
    def initialize(program, env)
      @program = program
      @top_level = env
    end

    def start
      evaluate(@program, @top_level)
    end

    def evaluate(node, env)
      case node.type
      when :unary
        evaluate_unary(node, env)
      when :binary
        evaluate_binary(node, env)
      when :number
        evaluate_number(node, env)
      when :boolean
        evaluate_boolean(node, env)
      when :string
        evaluate_string(node, env)
      when :program
        evaluate_program(node, env)
      when :block
        evaluate_block(node, env)
      when :assign
        evaluate_assign(node, env)
      when :varref
        evaluate_varref(node, env)
      when :if
        evaluate_if(node, env)
      when :func
        evaluate_func(node, env)
      when :call
        evaluate_call(node, env)
      when :return
        evaluate_return(node, env)
      end
    end

    UNARY_OPERATORS = {
      plus:  lambda { |v| v  },
      minus: lambda { |v| -v },
      not:   lambda { |v| !v },
    }

    def evaluate_unary(node, env)
      op = UNARY_OPERATORS[node.op]
      op.call(
        evaluate(node.lhs, env)
      )
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
      node.value
    end

    def evaluate_boolean(node, env)
      node.value
    end

    def evaluate_string(node, env)
      node.value
    end

    def evaluate_program(node, env)
      catch(:return) do
        evaluate_stmts(node.stmts, env)
      end
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
      env[node.lhs.lhs] = evaluate(node.rhs, env)
    end

    def evaluate_varref(node, env)
      if env.key?(node.lhs)
        env[node.lhs]
      else
        abort "var `#{node.lhs}` is not defined"
      end
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
      name = node.lhs
      if env.key?(name)
        call_user_func(node, env)
      elsif builtin_defined_func?(name)
        call_builtin_defined_func(node, env)
      elsif builtin_func?(name)
        call_builtin_func(node, env)
      else
        abort "func `#{name}` is not defined"
      end
    end

    def call_user_func(node, env)
      func = env[node.lhs]
      new_env = func.env.spawn
      args = evaluate_args(node, env)
      func.node.params.zip(args).each do |param, arg|
        new_env[param.lhs] = arg
      end
      catch(:return) do
        evaluate(func.node.body, new_env)
      end
    end

    def builtin_defined_func?(name)
      name == "defined"
    end

    def call_builtin_defined_func(node, env)
      env.key?(node.lhs)
    end

    BUILTIN_FUNCTIONS = {
      "puts" => lambda { |node, env, args| puts(*args) }
    }

    def builtin_func?(name)
      BUILTIN_FUNCTIONS.key?(name)
    end

    def call_builtin_func(node, env)
      func = BUILTIN_FUNCTIONS[node.lhs]
      args = evaluate_args(node, env)
      func.call(node, env, args)
    end

    def evaluate_return(node, env)
      args = evaluate_args(node, env)
      throw :return, *args
    end

    def evaluate_args(node, env)
      node.args.map { |arg| evaluate(arg, env) }
    end
  end
end
