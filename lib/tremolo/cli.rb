require_relative "tokenizer"
require_relative "parser"

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

    def evaluate(node)
      case node.type
      when :plus
        evaluate(node.lhs) + evaluate(node.rhs)
      when :minus
        evaluate(node.lhs) - evaluate(node.rhs)
      when :asterisk
        evaluate(node.lhs) * evaluate(node.rhs)
      when :slash
        evaluate(node.lhs) / evaluate(node.rhs)
      when :percent
        evaluate(node.lhs) % evaluate(node.rhs)
      when :number
        evaluate_number(node)
      when :program
        evaluate_program(node)
      when :assign
        evaluate_assign(node)
      when :ident
        evaluate_ident(node)
      end
    end

    def evaluate_number(node)
      node.lhs.to_i
    end

    def evaluate_program(node)
      last = nil
      node.stmts.each do |stmt|
        last = evaluate(stmt)
      end
      last
    end

    def evaluate_assign(node)
      @env[node.lhs] = evaluate(node.rhs)
    end

    def evaluate_ident(node)
      @env[node.lhs]
    end
  end
end
