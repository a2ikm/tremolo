require_relative "interpretor"

module Tremolo
  class CLI
    def initialize(argv = [])
      @argv = argv
    end

    def run
      source = read_source
      eval(source)
    end

    def read_source
      @argv.empty? ? $stdin.read : File.read(@argv.first)
    end

    def eval(source)
      Interpretor.new.eval(source)
    end
  end
end
