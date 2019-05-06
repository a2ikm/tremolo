#!/usr/bin/env ruby

require "test/unit/assertions"
include Test::Unit::Assertions

require_relative "lib/tremolo"

def test(expected, source)
  result = Tremolo::Interpretor.new.eval(source)
  assert_equal expected, result
end

test 0, "0"
test 42, "42"
test 3, "1 + 2"
test 2, "3 - 1"
test 6, "2 * 3"
test 2, "5 / 2"
test 1, "7 % 3"
test 5, "10 / 3 + 2"
test 9, "(1 + 2) * 3"
test 3, "1 + \n2"
test 3, "1 \n+ 2"
test 2, "1;2"
test 2, "1;;2"
test 2, ";;2"
test 8, "let answer = 7; 1 + answer"
test 11, "if 1 == 1 { 11 }"
test 22, "if 1 == 1 { 11; 22 }"
test 22, "if 1 == 2 { 11 } else { 22 }"
test 1, "let x = 1;\n if x > 0 {\n 1 \n} else {\n 2 \n}"
test 2, "let f = func() { 2 }; f()"
test 3, "let f = func(x) { x + 2 }; f(1)"
test 15, "let f = func(x, y) { x + y + 4 }; f(1,2)+8"
test 2, "let x = 1; let f = func() { let x = 2 }; f(); x "
test 2, "let f = func() { let x = 2 }; f(); if defined(x) { 1 } else { 2 } "
test 2, "let x = 1; let f = func() { x + 1 }; f()"
test 2, "let x = 1; let x = x + 1; x"
test 3, "let f1 = func() { func(x) { x + 1 } }; let f2 = f1(); f2(2)"
test 3, "let f = func() { let x = 0; func() { let x = x + 1; x } }; let c = f(); c(); c(); c()"
test 0, "func(){}; 0"
test 0, "func(){} == func(){}; 0"
test 0, "(func(){}); 0"
test 0, 'puts("This is test code."); 0'
test 2, "-1 * -2"
test 1, "-1 + 2"
test 0, "if !(1 == 0) { 0 } else { 1 }"
test 1, "if !!(1 == 0) { 0 } else { 1 }"
test 0, "if true { 0 } else { 1 }"
test 0, "if false { 1 } else { 0 }"
test 3, "1 +\n2"
test 3, "1 \n+ 2"
test 2, "1\n2"
test 3, "let x = 1\nlet x = x + 1\nx + 1"
test 2, "let f = func() { 1\n2 }\nf()"
test 1, "let f = func() { return 1\n2 }\nf()"
test 1, "return 1\n2"
test 1, "if true { return 1 }\n2"
test 2, "let x = 1\n let f = func(a) { a + 1 }\nf(x)"
test 0, " \n 0"
test 0, "\n \n0"
test 0, "0 "
test 0, "0\n"
