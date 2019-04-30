require_relative "tokenizer"
require_relative "parser"

module Tremolo
  class CLI
    def run
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

    def evaluate(node)
      case node.type
      when :+
        evaluate(node.lhs) + evaluate(node.rhs)
      when :-
        evaluate(node.lhs) - evaluate(node.rhs)
      when :*
        evaluate(node.lhs) * evaluate(node.rhs)
      when :/
        evaluate(node.lhs) / evaluate(node.rhs)
      when :%
        evaluate(node.lhs) % evaluate(node.rhs)
      when :number
        evaluate_number(node)
      end
    end

    def evaluate_number(node)
      node.lhs.to_i
    end
  end
end
