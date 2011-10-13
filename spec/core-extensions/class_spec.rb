require 'spec_helper'

class Myclass
  attr_property :prop
end

describe Class do
  before :all do
    @it=Myclass.new
  end
  it 'can have a property defined' do
    @it.prop 5
    @it.prop.should eql 5
  end
  it 'can have a prop unset' do
    @it.prop 5
    @it.prop nil
    @it.prop.should be_nil
  end
  it 'does not unset by query' do
    @it.prop 5
    @it.prop
    @it.prop.should_not be_nil
  end
end
