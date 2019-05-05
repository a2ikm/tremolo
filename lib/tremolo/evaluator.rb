module Tremolo
  class Environment
    def initialize
      @global = {}
      @stack = [@global]
    end

    def []=(key, value)
      env = lookup(key)
      if env
        env[key] = value
      else
        current[key] = value
      end
    end

    def [](key)
      env = lookup(key)
      env ? env[key] : nil
    end

    def lookup(key)
      @stack.reverse.detect { |env| env.key?(key) }
    end

    def current
      @stack.last
    end

    def push
      @stack.push({})
    end

    def pop
      @stack.pop
    end
  end

  class Evaluator
    def initialize
      @env = Environment.new
    end

    def evaluate(node)
      case node.type
      when :binary
        evaluate_binary(node)
      when :number
        evaluate_number(node)
      when :program, :stmts
        evaluate_stmts(node.stmts)
      when :assign
        evaluate_assign(node)
      when :ident
        evaluate_ident(node)
      when :if
        if evaluate(node.cond)
          evaluate(node.lhs)
        else
          evaluate(node.rhs)
        end
      when :func
        evaluate_func(node)
      when :call
        evaluate_call(node)
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

    def evaluate_binary(node)
      op = BINARY_OPERATORS[node.op]
      op.call(
        evaluate(node.lhs),
        evaluate(node.rhs),
      )
    end

    def evaluate_number(node)
      node.lhs.to_i
    end

    def evaluate_stmts(stmts)
      last = nil
      stmts.each do |stmt|
        last = evaluate(stmt)
      end
      last
    end

    def evaluate_assign(node)
      @env[node.lhs] = evaluate(node.rhs)
    end

    def evaluate_ident(node)
      @env[node.lhs]
    end

    def evaluate_func(node)
      node
    end

    def evaluate_call(node)
      func = @env[node.lhs]
      abort "func `#{node.lhs}` is not defined" if func.nil?

      @env.push
      func.params.zip(node.args).each do |param, arg|
        @env[param.lhs] = arg.lhs
      end
      evaluate(func.stmts)
    ensure
      @env.pop
    end
  end
end
