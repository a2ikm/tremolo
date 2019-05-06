require_relative "tokenizer"
require_relative "parser"
require_relative "evaluator"

module Tremolo
  class Interpretor
    def initialize
      @top_level = Environment.new
    end

    def eval(source)
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
      Evaluator.new(program, @top_level).start
    end
  end
end
