require_relative "tokenizer"

module Tremolo
  class CLI
    def run
      program = $stdin.read
      tokens = tokenize(program)
      evaluate(tokens)
    end

    def tokenize(program)
      Tokenizer.new(program).tokenize
    end

    def evaluate(tokens)
      stack = []
      while token = tokens.shift
        case token
        when "+"
          x, y = stack.pop.to_i, stack.pop.to_i
          stack.push(x + y)
        when "-"
          x, y = stack.pop.to_i, stack.pop.to_i
          stack.push(x - y)
        when "*"
          x, y = stack.pop.to_i, stack.pop.to_i
          stack.push(x * y)
        when "/"
          x, y = stack.pop.to_i, stack.pop.to_i
          stack.push(x / y)
        when "%"
          x, y = stack.pop.to_i, stack.pop.to_i
          stack.push(x % y)
        else
          stack.push(token.to_i)
        end
      end
      stack.pop
    end
  end
end
