require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
class AMEE::DataAbstraction::PrototypeCalculation
  def call_me
    #stub, because flexmock doesn't work for new instances during constructor
    @@called=true
  end
  cattr_accessor :called
end
describe AMEE::DataAbstraction::PrototypeCalculation do
  it 'can create an instance' do
    Transport.should be_a AMEE::DataAbstraction::PrototypeCalculation
  end
  it 'can be initialized with a DSL block' do
    AMEE::DataAbstraction::PrototypeCalculation.new {call_me}
    AMEE::DataAbstraction::PrototypeCalculation.called.should be_true
  end
  it 'can make a drill in the DSL block' do
    pc=AMEE::DataAbstraction::PrototypeCalculation.new {drill{label :alpha}}
    pc[:alpha].should be_a AMEE::DataAbstraction::Drill
  end
  it 'can make a profile item value in the DSL block' do
    pc=AMEE::DataAbstraction::PrototypeCalculation.new {profile{label :alpha}}
    pc[:alpha].should be_a AMEE::DataAbstraction::Profile
  end
  it 'can make an output in the DSL block' do
    pc=AMEE::DataAbstraction::PrototypeCalculation.new {output{label :alpha}}
    pc[:alpha].should be_a AMEE::DataAbstraction::Output
  end
  it 'can construct an ongoing calculation' do
    Transport.begin_calculation.should be_a AMEE::DataAbstraction::OngoingCalculation
  end
  it 'should make the terms of the ongoing calculation be their own instances' do
    oc=Transport.begin_calculation
    oc[:distance].value :somevalue
    oc[:distance].value.should eql :somevalue
    Transport[:distance].value.should be_nil
  end
  it 'should copy name, path, label when cloning ongoing' do
    [:path,:name,:label].each do |property|
      Transport.begin_calculation.send(property).should eql Transport.send(property)
    end
  end
end

