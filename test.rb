#!/usr/bin/env ruby

require "shellwords"
require "test/unit/assertions"
include Test::Unit::Assertions

def tremolo(program)
  program = Shellwords.shellescape(program)
  system "echo #{program} | bin/tremolo"
  $?.exitstatus
end

ret = tremolo("0")
assert_equal 0, ret

ret = tremolo("42")
assert_equal 42, ret

ret = tremolo("1 + 2")
assert_equal 3, ret

ret = tremolo("3 - 1")
assert_equal 2, ret

ret = tremolo("2 * 3")
assert_equal 6, ret

ret = tremolo("5 / 2")
assert_equal 2, ret

ret = tremolo("7 % 3")
assert_equal 1, ret

ret = tremolo("10 / 3 + 2")
assert_equal 5, ret

ret = tremolo("(1 + 2) * 3")
assert_equal 9, ret

ret = tremolo("1 + \n2")
assert_equal 3, ret

ret = tremolo("1 \n+ 2")
assert_equal 3, ret

ret = tremolo("1;2")
assert_equal 2, ret

ret = tremolo("1;;2")
assert_equal 2, ret

ret = tremolo(";;2")
assert_equal 2, ret

ret = tremolo("let answer = 7; 1 + answer")
assert_equal 8, ret
