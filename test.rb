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

ret = tremolo("1 2 +")
assert_equal 3, ret
