module Tremolo
  class CLI
    def run
      program = $stdin.read
      evaluate(program)
    end

    def evaluate(program)
      tokens = program.split(/\s+/)
      loop do
        a = tokens.pop
        case a
        when "+"
          x, y = tokens.pop.to_i, tokens.pop.to_i
          tokens.push(x + y)
        else
          return a.to_i
        end
      end
    end
  end
end
