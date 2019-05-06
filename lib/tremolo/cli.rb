require_relative "tokenizer"
require_relative "parser"
require_relative "evaluator"

module Tremolo
  class CLI
    def initialize(argv = [])
      @argv = argv
    end

    def run
      source = read_source
      tokens = tokenize(source)
      program = parse(tokens)
      evaluate(program)
    end

    def read_source
      @argv.empty? ? $stdin.read : File.read(@argv.first)
    end

    def tokenize(source)
      Tokenizer.new(source).tokenize
    end

    def parse(tokens)
      Parser.new(tokens).parse
    end

    def evaluate(program)
      Evaluator.new(program).start
    end
  end
end
