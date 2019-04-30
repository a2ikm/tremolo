require_relative "node"

module Tremolo
  class Node
    attr_reader :type, :lhs, :rhs

    def initialize(type, lhs, rhs = nil)
      @type = type
      @lhs = lhs
      @rhs = rhs
    end
  end

  class Parser
    def initialize(tokens)
      @tokens = tokens
      @len = @tokens.length
    end

    def parse
      @pos = 0
      parse_add
    end

    def parse_add
      mul = parse_mul
      %i(+ -).each do |op|
        return Node.new(op, mul, parse_add) if consume(op)
      end
      mul
    end

    def parse_mul
      number = parse_number
      %i(* / %).each do |op|
        return Node.new(op, number, parse_mul) if consume(op)
      end
      number
    end

    def parse_number
      token = consume(:number)
      return nil if token.nil?

      Node.new(:number, token.input.to_i)
    end

    def consume(type)
      return nil if current&.type != type
      token = current
      advance
      token
    end

    def advance
      @pos += 1
    end

    def current
      @tokens[@pos]
    end
  end
end
