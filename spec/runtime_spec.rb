require File.dirname(__FILE__) + '/spec_helper'

describe Runtime do
  before do
    @runtime = Min.runtime
  end
  
  it "should load file in load path" do
    @runtime.load("empty")
  end
  
  it "should raise when cant file file in load path" do
    proc { @runtime.load("poop") }.should raise_error
  end
  
  it "should eval 1" do
    @runtime.eval("1").should == Number.new(1)
  end

  it "should eval self" do
    @runtime.eval("self").should == @runtime.context.min_self
  end

  it "should eval Object" do
    @runtime.eval("Object").should be_a(Min::Object)
  end

  it "should eval Class" do
    @runtime.eval("Class").should be_a(Min::Class)
  end

  it "should eval eval" do
    @runtime.eval('eval("1")').should == Number.new(1)
  end

  it "should eval load" do
    @runtime.eval('load("empty")')
  end

  it "should raise when constant not found" do
    proc { @runtime[:Waaaaa?] }.should raise_error(ConstantNotFound)
  end
end
