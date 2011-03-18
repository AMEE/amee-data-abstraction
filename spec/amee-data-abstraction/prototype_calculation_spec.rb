require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
describe AMEE::DataAbstraction::Calculation do
  it 'can create an instance' do
    Transport.should be_a AMEE::DataAbstraction::PrototypeCalculation
  end
end

