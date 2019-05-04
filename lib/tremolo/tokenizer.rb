module Tremolo
  SINGLE_TOKENS = {
    "=" => :equal,
    "+" => :plus,
    "-" => :minus,
    "*" => :asterisk,
    "/" => :slash,
    "%" => :percent,
    "(" => :lparen,
    ")" => :rparen,
    ";" => :semicolon,
  }

  KEYWORD_TOKENS = {
    "let" => :let,
  }

  class Token
    attr_reader :type, :input

    def initialize(type, input)
      @type = type
      @input = input
    end
  end

  class Tokenizer
    def initialize(source)
      @source = source
      @len = @source.length
    end

    def tokenize
      @pos = 0
      @tokens = []

      while @pos < @len
        if whitespace?(current)
          advance
          next
        end

        if newline?(current)
          @tokens << Token.new(:newline, read_newline)
          advance
          next
        end

        if type = SINGLE_TOKENS[current]
          @tokens << Token.new(type, current)
          advance
          next
        end

        if digit?(current)
          @tokens << Token.new(:number, read_digit)
          advance
          next
        end

        if ident?(current)
          input = read_ident
          if type = KEYWORD_TOKENS[input]
            @tokens << Token.new(type, input)
          else
            @tokens << Token.new(:ident, input)
          end
          advance
          next
        end
      end

      @tokens
    end

    def whitespace?(char)
      char && char.match?(/\A[[:blank:]]+\z/)
    end

    def digit?(char)
      char && char.match?(/\A[[:digit:]]\z/)
    end

    def read_digit
      pos = @pos
      while @pos < @len
        if digit?(peek)
          advance
        else
          break
        end
      end
      @source[pos..@pos]
    end

    def newline?(char)
      char && char.match?(/\A[\r\n]\z/)
    end

    def read_newline
      pos = @pos
      advance if current == "\r" && peek == "\n"
      @source[pos..@pos]
    end

    def ident?(char)
      char && char.match?(/\A[_a-z]\z/)
    end

    def read_ident
      pos = @pos
      while @pos < @len
        if ident?(peek)
          advance
        else
          break
        end
      end
      @source[pos..@pos]
    end

    def current
      @source[@pos]
    end

    def peek
      @source[@pos+1]
    end

    def advance
      @pos += 1
    end
  end
end
