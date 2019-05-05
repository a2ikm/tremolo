module Tremolo
  class Node
    attr_reader :type,
                :op,        # binary operator
                :lhs,       # left-hand side
                :rhs,       # right-hand side
                :stmts,     # compound statements
                :cond,      # if's condition statement
                :params,    # function parameters
                :args       # function arguments

    def initialize(type, op: nil, lhs: nil, rhs: nil, stmts: nil, cond: nil, params: nil, args: nil)
      @type = type
      @op = op
      @lhs = lhs
      @rhs = rhs
      @stmts = stmts
      @cond = cond
      @params = params
      @args = args
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

    # stmt -> let ident = assignee
    # stmt -> if equality block
    # stmt -> equality
    def parse_stmt
      if consume(:let)
        token = expect(:ident)
        expect(:assign)
        Node.new(:assign, lhs: token.input, rhs: parse_assignee)
      elsif consume(:if)
        cond = parse_equality
        raise "parse error" if cond.nil?
        block = parse_block
        alt = nil
        if consume(:else)
          alt = parse_block
        end
        Node.new(:if, cond: cond, lhs: block, rhs: alt)
      else
        parse_equality
      end
    end

    # assignee : equality
    # assignee : func(params) block
    def parse_assignee
      if token = consume(:func)
        expect(:lparen)
        params = parse_params
        expect(:rparen)
        stmts = parse_block
        Node.new(:func, params: params, stmts: stmts)
      else
        parse_equality
      end
    end

    def parse_params
      params = []
      if token = consume(:ident)
        params << Node.new(:ident, lhs: token.input)
        while consume(:comma)
          token = expect(:ident)
          params << Node.new(:ident, lhs: token.input)
        end
      end
      params
    end

    # block -> { stmts }
    def parse_block
      stmts = []
      expect(:lbrace)
      loop do
        stmts << parse_stmt
        next if consume(:semicolon)
        break if consume(:rbrace)
      end
      Node.new(:stmts, stmts: stmts.compact)
    end

    # equality  -> relational equality'
    # equality' -> empty
    # equality' -> == equality
    # equality' -> != equality
    def parse_equality
      relational = parse_relational
      if consume(:eq)
        Node.new(:binary, op: :eq, lhs: relational, rhs: parse_equality)
      elsif consume(:ne)
        Node.new(:binary, op: :ne, lhs: relational, rhs: parse_equality)
      else
        relational
      end
    end

    # relational  -> add relational'
    # relational' -> empty
    # relational' -> <  relational
    # relational' -> <= relational
    # relational' -> >  relational
    # relational' -> >= relational
    def parse_relational
      add = parse_add
      if consume(:lt)
        Node.new(:binary, op: :lt, lhs: add, rhs: parse_relational)
      elsif consume(:lteq)
        Node.new(:binary, op: :lteq, lhs: add, rhs: parse_relational)
      elsif consume(:gt)
        Node.new(:binary, op: :gt, lhs: add, rhs: parse_relational)
      elsif consume(:gteq)
        Node.new(:binary, op: :gteq, lhs: add, rhs: parse_relational)
      else
        add
      end
    end

    # add  -> mul add'
    # add' -> empty
    # add' -> {+-} add
    def parse_add
      mul = parse_mul
      if consume(:plus)
        Node.new(:binary, op: :add, lhs: mul, rhs: parse_add)
      elsif consume(:minus)
        Node.new(:binary, op: :sub, lhs: mul, rhs: parse_add)
      else
        mul
      end
    end

    # mul  -> term mul'
    # mul' -> empty
    # mul' -> {*/%} mul
    def parse_mul
      term = parse_term
      if consume(:asterisk)
        Node.new(:binary, op: :mul, lhs: term, rhs: parse_mul)
      elsif consume(:slash)
        Node.new(:binary, op: :div, lhs: term, rhs: parse_mul)
      elsif consume(:percent)
        Node.new(:binary, op: :mod, lhs: term, rhs: parse_mul)
      else
        term
      end
    end

    # term -> number
    # term -> ident
    # term -> ident ( args )
    # term -> ( equality )
    def parse_term
      if consume(:lparen)
        equality = parse_equality
        expect(:rparen)
        return equality
      end

      if token = consume(:number)
        return Node.new(:number, lhs: token.input.to_i)
      end

      if token = consume(:ident)
        if consume(:lparen)
          args = parse_args
          expect(:rparen)
          return Node.new(:call, lhs: token.input, args: args)
        else
          return Node.new(:ident, lhs: token.input)
        end
      end
    end

    def parse_args
      args = []
      if arg = parse_equality
        args << arg
        while consume(:comma)
          args << parse_equality
        end
      end
      args
    end

    def consume(type)
      return nil if current&.type != type
      token = current
      advance
      token
    end

    def expect(type)
      if token = consume(type)
        token
      else
        abort "parse error: expected #{type} but got #{current&.type}"
      end
    end

    def advance
      @pos += 1 + count_upcoming_skips
    end

    def current
      @tokens[@pos]
    end

    def peek
      @tokens[@pos + 1 + count_upcoming_skips]
    end

    def count_upcoming_skips
      skips = 0
      while @tokens[@pos + 1 + skips]&.type == :newline
        skips += 1
      end
      skips
    end
  end
end
