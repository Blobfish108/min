require File.dirname(__FILE__) + "/spec_helper"

describe Parser do
  before do
    @parser = Parser.new
  end
  
  def self.it_should_parse(code, &expected)
    it "should parse #{code}" do
      begin
        @parser.parse(code).nodes.should == instance_eval(&expected)
      rescue
        puts "Tokens:" + Tokenizer.new.tokenize(code).inspect
        raise
      end
    end
  end
  
  # Literals
  it_should_parse(%{1}) { [Number.new(1)] }
  it_should_parse(%{"ohaie"}) { [Min::String.new("ohaie")] }
  
  # Assign
  it_should_parse(%{x = 1}) { [Assign.new(:x, Number.new(1))] }
  
  # Call
  it_should_parse(%{x}) { [Call.new(nil, :x, [])] }
  it_should_parse(%{x()}) { [Call.new(nil, :x, [])] }
  it_should_parse(%{x 1}) { [Call.new(nil, :x, [Arg.new(Number.new(1))])] }
  it_should_parse(%{x(1)}) { [Call.new(nil, :x, [Arg.new(Number.new(1))])] }
  it_should_parse(%{x(1, "1")}) { [Call.new(nil, :x, [Arg.new(Number.new(1)), Arg.new(Min::String.new("1"))])] }
  it_should_parse(%{x 1, "1"}) { [Call.new(nil, :x, [Arg.new(Number.new(1)), Arg.new(Min::String.new("1"))])] }
  it_should_parse(%{1[2]}) { [Call.new(Number.new(1), :[], [Arg.new(Number.new(2))])] }
  it_should_parse(%{1[2] = 3}) { [Call.new(Number.new(1), :[]=, [Arg.new(Number.new(2)), Arg.new(Number.new(3))])] }
  it_should_parse(%{x(*[1, 2])}) { [Call.new(nil, :x, [Arg.new(Min::Array.new([Number.new(1), Number.new(2)]), true)])] }
  
  # Call w/ closure
  it_should_parse(%{x:\n  1}) { [
    Call.new(nil, :x, [
      Arg.new(Closure.new(
        Block.new([
          Number.new(1)
        ]),
      []))
    ])
  ] }
  it_should_parse(%{x: a |\n  1}) { [
    Call.new(nil, :x, [Arg.new(Closure.new(
      Block.new([
        Number.new(1)
      ]),
      [Param.new(:a, nil, false)]))
    ])
  ] }
  it_should_parse(%{x(1):\n  1\n  2}) { [
    Call.new(nil, :x, [
      Arg.new(Number.new(1)),
      Arg.new(Closure.new(
        Block.new([
          Number.new(1),
          Number.new(2)
        ]),
      []))
    ])
  ] }
  it_should_parse(%{x:\n  1\n2}) { [
    Call.new(nil, :x, [
      Arg.new(Closure.new(
        Block.new([
          Number.new(1)
        ]),
      []))
    ]),
    Number.new(2)
  ] }
  it_should_parse(%{x:\n  y:\n    1\n  2}) { [
    Call.new(nil, :x, [
      Arg.new(Closure.new(
        Block.new([
          Call.new(nil, :y, [
            Arg.new(Closure.new(Block.new([Number.new(1)]), []))
          ]),
          Number.new(2)
        ]),
      []))
    ])
  ] }
  it_should_parse(%{x {1}}) { [Call.new(nil, :x, [Arg.new(Closure.new(Block.new([Number.new(1)]), []))])] }
  it_should_parse(%{x(2, {1})}) { [Call.new(nil, :x, [Arg.new(Number.new(2)), Arg.new(Closure.new(Block.new([Number.new(1)]), []))])] }
  it_should_parse(%{x { a | 1}}) { [Call.new(nil, :x, [Arg.new(Closure.new(Block.new([Number.new(1)]), [Param.new(:a, nil, false)]))])] }
  it_should_parse(%{x: 1}) { [Call.new(nil, :x, [Arg.new(Closure.new(Block.new([Number.new(1)]), []))])] }
  it_should_parse(%{x: a | 1}) { [Call.new(nil, :x, [Arg.new(Closure.new(Block.new([Number.new(1)]), [Param.new(:a, nil, false)]))])] }
  it_should_parse(%{x(1): a | 1}) { [Call.new(nil, :x, [Arg.new(Number.new(1)), Arg.new(Closure.new(Block.new([Number.new(1)]), [Param.new(:a, nil, false)]))])] }
  it_should_parse(%{if true: 1}) { [Call.new(nil, :if, [Arg.new(Call.new(nil, :true, [])), Arg.new(Closure.new(Block.new([Number.new(1)]), []))])] }
  
  # Closure
  it_should_parse(%{{ a | 1 }}) { [Closure.new(Block.new([Number.new(1)]), [Param.new(:a, nil, false)])] }
  it_should_parse(%{{ *a | 1 }}) { [Closure.new(Block.new([Number.new(1)]), [Param.new(:a, nil, true)])] }
  it_should_parse(%{{ a=2 | 1 }}) { [Closure.new(Block.new([Number.new(1)]), [Param.new(:a, Number.new(2), false)])] }
  
  # Object calls
  it_should_parse(%{1.x}) { [Call.new(Number.new(1), :x, [])] }
  it_should_parse(%{x.y}) { [Call.new(Call.new(nil, :x, []), :y, [])] }
  it_should_parse(%{1.x.y}) { [Call.new(Call.new(Number.new(1), :x, []),
                                                :y, [])] }
  
  # Special object calls
  it_should_parse(%{a.x = 1}) { [Call.new(Call.new(nil, :a, []), :x=, [Arg.new(Number.new(1))])] }
  it_should_parse(%{x == 1}) { [Call.new(Call.new(nil, :x, []), :==, [Arg.new(Number.new(1))])] }
  it_should_parse(%{x + 1}) { [Call.new(Call.new(nil, :x, []), :+, [Arg.new(Number.new(1))])] }
  it_should_parse(%{x && 1}) { [Call.new(Call.new(nil, :x, []), :"&&", [Arg.new(Number.new(1))])] }
  it_should_parse(%{!1}) { [Call.new(Number.new(1), :"!", [])] }
  it_should_parse(%{-1}) { [Call.new(Number.new(1), :"-", [])] }
  
  # Comments
  it_should_parse(%{# I IZ COMMENTZIN}) { [] }
  
  # Symbol
  it_should_parse(%{:ohaie}) { [Min::Symbol.new(:ohaie)] }
  
  # Array
  it_should_parse(%{[]}) { [Min::Array.new([])] }
  it_should_parse(%{[1]}) { [Min::Array.new([Number.new(1)])] }
  it_should_parse(%{[1, 2]}) { [Min::Array.new([Number.new(1), Number.new(2)])] }
  
  # Hash
  it_should_parse(%{[:]}) { [Min::Hash.new({})] }
  it_should_parse(%{[1: 2]}) { [Min::Hash.new(Number.new(1) => Number.new(2))] }
  it_should_parse(%{[a: 2]}) { [Min::Hash.new(Min::Symbol.new(:a) => Number.new(2))] }
  it_should_parse(%{["a" : 2]}) { [Min::Hash.new(Min::String.new("a") => Number.new(2))] }
end