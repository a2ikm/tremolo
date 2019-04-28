#!/usr/bin/env ruby

require "test/unit/assertions"
include Test::Unit::Assertions

def tremolo(program)
  system "echo #{program} | bin/tremolo"
  $?.exitstatus
end

ret = tremolo("0")
assert_equal 0, ret
