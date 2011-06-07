require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'

describe Output do
  it 'is visible only if it is set' do
    x=Output.new
    x.visible?.should be_true
    x.value 5
    x.visible?.should be_true
  end
end