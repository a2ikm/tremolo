require_relative "node"

module Tremolo
  class Node
    attr_reader :type, :lhs, :rhs

    def initialize(type, lhs: nil, rhs: nil)
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

    # add  -> mul add'
    # add' -> empty
    # add' -> {+-} add
    def parse_add
      mul = parse_mul
      %i(plus minus).each do |op|
        return Node.new(op, lhs: mul, rhs: parse_add) if consume(op)
      end
      mul
    end

    # mul  -> term mul'
    # mul' -> empty
    # mul' -> {*/%} mul
    def parse_mul
      number = parse_term
      %i(asterisk slash percent).each do |op|
        return Node.new(op, lhs: number, rhs: parse_mul) if consume(op)
      end
      number
    end

    # term -> number
    # term -> ( add )
    def parse_term
      if consume(:lparen)
        add = parse_add
        abort "parse error" unless consume(:rparen)
        return add
      end

      parse_number
    end

    def parse_number
      token = consume(:number)
      return nil if token.nil?

      Node.new(:number, lhs: token.input.to_i)
    end

    def consume(type)
      while current&.type == :newline
        advance
      end
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
