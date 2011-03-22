require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
describe Calculation do
  
  it 'can create an instance' do
    Transport.should be_a Calculation
  end
  it 'should have ordered terms, with labels' do
    Transport.terms.labels.should eql [:fuel,:size,:distance,:co2]
  end
  it 'should have amee paths for the terms' do
    Transport.terms.paths.should eql ['fuel','size','distance',:default]
  end
  it 'should have human names for the terms' do
    Transport.terms.names.
      should eql ['Fuel Type','Vehicle Size','Distance Driven','Carbon Dioxide']
  end
  it 'should return the inputs' do
    Transport.inputs.labels.should  eql [:fuel,:size,:distance]
  end
  it 'should return the outputs' do
    Transport.outputs.labels.should  eql [:co2]
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
  it 'knows to get terms that come before or after others' do
    Transport.before(:distance).labels.
      should eql [:fuel,:size]
    Transport.after(:distance).map(&:label).
      should eql [:co2]
  end
  it 'delegates selectors to terms list' do
    Transport.drills.labels.should eql [:fuel,:size]
  end
end

