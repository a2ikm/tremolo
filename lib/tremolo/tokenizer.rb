module Tremolo
  class Tokenizer
    def initialize(program)
      @program = program
      @len = @program.length
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
      @program[pos..@pos]
    end

    def char
      @program[@pos]
    end

    def peek
      @program[@pos+1]
    end

    def advance
      @pos += 1
    end
  end
end
