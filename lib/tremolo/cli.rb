module Tremolo
  class CLI
    def run
      program = $stdin.read
      program.to_i
    end
  end
end
