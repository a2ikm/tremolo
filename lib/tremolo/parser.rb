require_relative "node"

module Tremolo
  class Node
    attr_reader :type, :lhs, :rhs, :stmts

    def initialize(type, lhs: nil, rhs: nil, stmts: nil)
      @type = type
      @lhs = lhs
      @rhs = rhs
      @stmts = stmts
    end
  end

  class Parser
    def initialize(tokens)
      @tokens = tokens
      @len = @tokens.length
    end

    def parse
      @pos = 0
      parse_program
    end

    # program  -> stmt program'
    # program' -> empty
    # program' -> ; program
    def parse_program
      stmts = []
      stmts << parse_stmt
      while consume(:semicolon)
        stmts << parse_stmt
      end
      Node.new(:program, stmts: stmts.compact)
    end

    # stmt -> let ident = add
    # stmt -> add
    def parse_stmt
      if consume(:let)
        token = consume(:ident)
        raise "parse error" if token.nil?
        raise "parse error" if !consume(:equal)
        Node.new(:assign, lhs: token.input, rhs: parse_add)
      else
        parse_add
      end
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
    # term -> ident
    # term -> ( add )
    def parse_term
      if consume(:lparen)
        add = parse_add
        abort "parse error" unless consume(:rparen)
        return add
      end

      if token = consume(:number)
        return Node.new(:number, lhs: token.input.to_i)
      end

      if token = consume(:ident)
        return Node.new(:ident, lhs: token.input)
      end
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
