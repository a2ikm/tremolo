module Tremolo
  class CLI
    def run
      program = $stdin.read
      evaluate(program)
    end

    def evaluate(program)
      tokens = program.split(/\s+/)
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
