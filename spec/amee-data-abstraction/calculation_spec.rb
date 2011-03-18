require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
describe AMEE::DataAbstraction::Calculation do
  
  it 'can create an instance' do
    Transport.should be_a AMEE::DataAbstraction::Calculation
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
end

