module Tremolo
  class CLI
    def run
      program = $stdin.read
      evaluate(program)
    end

    def evaluate(program)
      program.to_i
    end
  end
end
