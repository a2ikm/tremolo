module Tremolo
  class Tokenizer
    def initialize(source)
      @source = source
      @len = @source.length
    end

    def tokenize
      @pos = 0
      @tokens = []

      while @pos < @len
        if whitespace?(char)
          advance
          next
        end

        if char == "+" || char == "-" || char == "*" || char == "/" || char == "%"
          @tokens << char
          advance
          next
        end

        if digit?(char)
          @tokens << read_digit
          advance
          next
        end
      end

      @tokens
    end

    def whitespace?(char)
      char && char.match?(/\A[[:space:]]+\z/)
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

    def char
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
