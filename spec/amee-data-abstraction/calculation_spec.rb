require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
describe Calculation do
  
  it 'can create an instance' do
    Transport.should be_a Calculation
  end
  it 'should have ordered terms, with labels' do
    Transport.terms.values.map(&:label).should eql [:fuel,:size,:distance,:co2]
  end
  it 'should have amee paths for the terms' do
    Transport.terms.values.map(&:path).should eql ['fuel','size','distance',:default]
  end
  it 'should have human names for the terms' do
    Transport.terms.values.map(&:name).
      should eql ['Fuel Type','Vehicle Size','Distance Driven','Carbon Dioxide']
  end
  it 'should return the inputs' do
    Transport.inputs.values.map(&:label).should  eql [:fuel,:size,:distance]
  end
  it 'should return the outputs' do
    Transport.outputs.values.map(&:label).should  eql [:co2]
  end
  it 'can return a term via []' do
    Transport[:co2].label.should eql :co2
  end
  it 'when copied, should deep copy the values' do
    x=Transport.clone
    x[:co2].value :somevalue
    x[:co2].value.should eql :somevalue
    Transport[:co2].value.should be_nil
  end
end

