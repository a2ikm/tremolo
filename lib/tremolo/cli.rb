require_relative "tokenizer"
require_relative "parser"
require_relative "evaluator"

module Tremolo
  class CLI
    def run
      @env = {}
      source = $stdin.read
      tokens = tokenize(source)
      program = parse(tokens)
      evaluate(program)
    end

    def tokenize(source)
      Tokenizer.new(source).tokenize
    end

    def parse(tokens)
      Parser.new(tokens).parse
    end

    def evaluate(program)
      Evaluator.new.evaluate(program)
    end
  end
end
