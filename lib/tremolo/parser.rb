module Tremolo
  class Node
    attr_reader :type,
                :op,        # binary operator
                :lhs,       # left-hand side
                :rhs,       # right-hand side
                :stmts,     # compound statements
                :body,      # body block
                :cond,      # if's condition statement
                :params,    # function parameters
                :args       # function arguments

    #
    ## binary
    # node
    #   type = binary
    #   op = {eq,ne,lt,lteq,gt,gteq,add,sub,mul,div,mod}
    #   lhs = node(type=*)
    #   rhs = node(type=*)
    #
    ## program
    # node
    #   type = program
    #   stmts = []node(type=*)
    #
    ## if
    # node
    #   type = if
    #   cond = node(type=*)
    #   lhs = node(type=block) : then branch
    #           stmts = []node(type=*)
    #   rhs = node(type=block) or nil : else branch
    #           stmts = []node(type=*)
    #
    ## func
    # node
    #   type = func
    #   params = []node(type=ident)
    #   body = node(type=block)
    #            stmts = []node(type=*)
    #
    def initialize(type, op: nil, lhs: nil, rhs: nil, stmts: nil, body: nil, cond: nil, params: nil, args: nil)
      @type = type
      @op = op
      @lhs = lhs
      @rhs = rhs
      @stmts = stmts
      @body = body
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

    # stmt -> let ident = expression
    # stmt -> if expression block
    # stmt -> expression
    def parse_stmt
      if consume(:let)
        token = expect(:ident)
        expect(:assign)
        Node.new(:assign, lhs: token.input, rhs: parse_expression)
      elsif consume(:if)
        cond = parse_expression
        raise "parse error" if cond.nil?
        block = parse_block
        alt = nil
        if consume(:else)
          alt = parse_block
        end
        Node.new(:if, cond: cond, lhs: block, rhs: alt)
      else
        parse_expression
      end
    end

    # expression -> equality
    # expression -> ! expression
    def parse_expression
      if consume(:bang)
        Node.new(:unary, op: :not, lhs: parse_expression)
      else
        parse_equality
      end
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
      Node.new(:block, stmts: stmts.compact)
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

    # mul  -> unary mul'
    # mul' -> empty
    # mul' -> {*/%} mul
    def parse_mul
      unary = parse_unary
      if consume(:asterisk)
        Node.new(:binary, op: :mul, lhs: unary, rhs: parse_mul)
      elsif consume(:slash)
        Node.new(:binary, op: :div, lhs: unary, rhs: parse_mul)
      elsif consume(:percent)
        Node.new(:binary, op: :mod, lhs: unary, rhs: parse_mul)
      else
        unary
      end
    end

    # unary -> term
    # unary -> + term
    # unary -> - term
    def parse_unary
      if consume(:plus)
        Node.new(:unary, op: :plus, lhs: parse_term)
      elsif consume(:minus)
        Node.new(:unary, op: :minus, lhs: parse_term)
      else
        parse_term
      end
    end

    # term -> number
    # term -> "\"" string "\""
    # term -> ident
    # term -> ident ( args )
    # term -> func(params) block
    # term -> ( expression )
    def parse_term
      if consume(:func)
        expect(:lparen)
        params = parse_params
        expect(:rparen)
        body = parse_block
        return Node.new(:func, params: params, body: body)
      end

      if consume(:lparen)
        expression = parse_expression
        expect(:rparen)
        return expression
      end

      if consume(:dquote)
        token = expect(:string)
        expect(:dquote)
        return Node.new(:string, lhs: token.input)
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

    def parse_args
      args = []
      if arg = parse_expression
        args << arg
        while consume(:comma)
          args << parse_expression
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
