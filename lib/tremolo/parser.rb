module Tremolo
  class Node
    FIELDS = [
      :type,
      :op,        # binary operator
      :lhs,       # left-hand side
      :rhs,       # right-hand side
      :stmts,     # compound statements
      :body,      # body block
      :cond,      # if's condition statement
      :params,    # function parameters
      :args,      # function arguments
      :value,     # immediate value
      :name,      # function's and variable's name
    ]

    attr_reader *FIELDS

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
    def initialize(type, **options)
      @type = type
      options.slice(*(FIELDS - [:type])).each do |field, value|
        instance_variable_set("@#{field}", value)
      end
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
      skip_skips
      stmts = []
      while @pos < @len
        stmts << parse_stmt
        consume(:semicolon)
      end
      Node.new(:program, stmts: stmts.compact)
    end

    # stmt -> let vardef = expression
    # stmt -> if expression block
    # stmt -> return args
    # stmt -> expression
    def parse_stmt
      if consume(:let)
        token = expect(:ident)
        vardef = Node.new(:vardef, name: token.input)
        expect(:assign)
        Node.new(:assign, lhs: vardef, rhs: parse_expression)
      elsif consume(:if)
        cond = parse_expression
        raise "parse error" if cond.nil?
        block = parse_block
        alt = nil
        if consume(:else)
          alt = parse_block
        end
        Node.new(:if, cond: cond, lhs: block, rhs: alt)
      elsif consume(:return)
        Node.new(:return, args: parse_args)
      else
        parse_expression
      end
    end

    # expression -> equality
    def parse_expression
      parse_equality
    end

    # block -> { stmts }
    def parse_block
      stmts = []
      expect(:lbrace)
      until consume(:rbrace)
        stmts << parse_stmt
        consume(:semicolon)
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

    # unary -> ! unary
    # unary -> term
    # unary -> + term
    # unary -> - term
    def parse_unary
      if consume(:bang)
        Node.new(:unary, op: :not, lhs: parse_unary)
      elsif consume(:plus)
        Node.new(:unary, op: :plus, lhs: parse_term)
      elsif consume(:minus)
        Node.new(:unary, op: :minus, lhs: parse_term)
      else
        parse_term
      end
    end

    # term -> number
    # term -> "\"" string "\""
    # term -> true
    # term -> false
    # term -> varref
    # term -> varref ( args )
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
        return Node.new(:string, value: token.input)
      end

      if token = consume(:number)
        return Node.new(:number, value: token.input.to_i)
      end

      if token = consume(:true)
        return Node.new(:boolean, value: true)
      end

      if token = consume(:false)
        return Node.new(:boolean, value: false)
      end

      if token = consume(:ident)
        if consume(:lparen)
          args = parse_args
          expect(:rparen)
          return Node.new(:call, name: token.input, args: args)
        else
          return Node.new(:varref, name: token.input)
        end
      end
    end

    def parse_params
      params = []
      if token = consume(:ident)
        params << Node.new(:vardef, name: token.input)
        while consume(:comma)
          token = expect(:ident)
          params << Node.new(:vardef, name: token.input)
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

    SKIPPED_TOKENS = %i(newline whitespace)

    def count_upcoming_skips
      skips = 0
      while SKIPPED_TOKENS.include?(@tokens[@pos + 1 + skips]&.type)
        skips += 1
      end
      skips
    end

    def skip_skips
      while SKIPPED_TOKENS.include?(current&.type)
        advance
      end
    end
  end
end
