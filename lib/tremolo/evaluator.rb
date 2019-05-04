module Tremolo
  class Evaluator
    def initialize
      @env = {}
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
      when :eq
        evaluate(node.lhs) == evaluate(node.rhs)
      when :ne
        evaluate(node.lhs) != evaluate(node.rhs)
      when :lt
        evaluate(node.lhs) < evaluate(node.rhs)
      when :lteq
        evaluate(node.lhs) <= evaluate(node.rhs)
      when :gt
        evaluate(node.lhs) > evaluate(node.rhs)
      when :gteq
        evaluate(node.lhs) >= evaluate(node.rhs)
      when :number
        evaluate_number(node)
      when :program, :block
        evaluate_stmts(node.stmts)
      when :assign
        evaluate_assign(node)
      when :ident
        evaluate_ident(node)
      when :if
        if evaluate(node.cond)
          evaluate(node.lhs)
        else
          evaluate(node.rhs)
        end
      end
    end

    def evaluate_number(node)
      node.lhs.to_i
    end

    def evaluate_stmts(stmts)
      last = nil
      stmts.each do |stmt|
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
